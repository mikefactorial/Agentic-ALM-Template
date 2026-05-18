---
applyTo: "src/webresources/**"
---

# Web Resource Development

## Project Layout

Web resources are organized by solution under `src/webresources/`:

| Solution | Notes |
|----------|-------|
| `{solutionPrefix}_{solutionName}/` | Read from `solutionAreas[].prefix` + `solutionAreas[].name` in `environment-config.json` |

Each web resource directory follows the naming convention `WR-{Name}/` and typically contains:
- `src/main.ts` — Entry point; exports the namespace object Dataverse calls
- `vite.config.ts` — Build configuration (must use IIFE library mode — see Critical Rules)
- `package.json` — npm dependencies
- `tsconfig.json` — TypeScript configuration
- `dist/` — Compiled output (generated; not committed to source control)

## When to Use a Web Resource

| Scenario | Use |
|----------|-----|
| Form script (OnLoad, OnChange, OnSave) | Web resource |
| Ribbon command handler | Web resource |
| Custom UI component embedded on a form | PCF control (`src/controls/`) |
| Standalone web app hosted in Power Apps | Code app (`src/codeapps/`) |

## Naming Conventions

| Element | Convention | Example |
|---------|-----------|---------|
| Directory | `WR-{Name}/` | `WR-AccountForm/` |
| Logical name | `{prefix}_/scripts/{Name}.js` | `acm_/scripts/AccountForm.js` |
| Namespace export | Matches `{Name}` | `export namespace AccountForm` |
| Function registered in Dataverse | `{Name}.onLoad` | `AccountForm.onLoad` |

> `{prefix}` comes from `solutionAreas[x].prefix` in `environment-config.json`. Never hardcode it.

## Entry Point Pattern

`src/main.ts` must export a namespace object. The IIFE build converts this to `window.{Name}` at runtime — the function name registered in the form or ribbon designer must match exactly:

```typescript
export namespace {Name} {
  export function onLoad(executionContext: Xrm.Events.EventContext): void {
    const formContext = executionContext.getFormContext();
    // your logic here
  }

  export function onChange(executionContext: Xrm.Events.EventContext): void {
    const formContext = executionContext.getFormContext();
    // your logic here
  }
}
```

Install Xrm typings if using the Xrm API: `npm install --save-dev @types/xrm`

## Vite Build Requirements

Web resources MUST use Vite in `library` mode with `formats: ['iife']` and content hashing disabled. Key requirements in `vite.config.ts`:

```typescript
build: {
  lib: {
    entry: resolve(__dirname, 'src/main.ts'),
    name: '{Name}',              // becomes window.{Name} at runtime
    formats: ['iife'],
    fileName: () => '{Name}.js', // fixed filename — no hash
  },
  rollupOptions: {
    output: {
      assetFileNames: '[name][extname]', // no hash
    },
  },
}
```

## map.xml Wiring

Each web resource is mapped into the solution package via `map.xml` in the solution directory. The `<FileToPath>` element points the packager to the compiled `dist/` output:

```xml
<FileToPath
  map="WebResources\{prefix}_\scripts\{Name}.js"
  to="..\..\..\webresources\{solutionAreaFolder}\WR-{Name}\dist" />
```

- `map` — path SolutionPackager expects inside the solution source (use `\` separators)
- `to` — relative to `src/solutions/{mainSolution}/src/` (three `..` levels up reaches `src/`)
- If `map.xml` already exists, add a new `<FileToPath>` entry; never create a second `SolutionPackagerSwitches` property in the `.cdsproj`

## environment-config.json Reference

| Field | Purpose |
|-------|---------|
| `solutionAreas[x].prefix` | Publisher prefix for logical names |
| `solutionAreas[x].cdsproj` | Solution `.cdsproj` to add the `map.xml` reference to |
| `solutionAreas[x].mainSolution` | Solution folder name for map.xml path resolution |
| `solutionAreas[x].webResourcePreBuildPaths` | Paths read by `Build-WebResources.ps1` during CI — append here when adding a new web resource |

## Critical Rules

1. **IIFE output only** — never switch to ES module format (`esm`, `es`). Dataverse calls exported functions as globals (`window.{Name}.onLoad`); ES modules break this entirely.
2. **No content hashing** — filenames must be stable across builds. `fileName: () => '{Name}.js'` must return a literal string, not use the default Vite hash pattern.
3. **Function name in Dataverse must match the namespace name exactly** — the value registered in the form designer (e.g. `AccountForm.onLoad`) must match the exported namespace and function name in `src/main.ts`.
4. **Web resource metadata must exist in solution source** — after creating the web resource in Dataverse and adding it to your feature solution, run `pac solution sync` to pull the `customizations.xml` entry into `src/`. The `map.xml` only maps the compiled file, not the metadata.
5. **`webResourcePreBuildPaths` must be updated** — CI will not build the web resource during outer-loop packaging unless the path is listed in `environment-config.json`.
6. **Do not commit `dist/`** — compiled output is generated during build and should be in `.gitignore`. The `map.xml` reference handles packaging at build time.
