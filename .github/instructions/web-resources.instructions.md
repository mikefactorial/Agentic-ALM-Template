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
  to="..\..\..\..\..\webresources\{solutionAreaFolder}\WR-{Name}\dist" />
```

### Why five `..` levels?

`dotnet build` recreates the solution's `src/` tree inside `obj\Metadata\` and runs the packager from there. The `to` path is resolved **relative to `obj\Metadata\WebResources\`** — not relative to the `.cdsproj` or `map.xml` file itself:

```
obj\Metadata\WebResources\   ← packager working directory
  ..  (1) → obj\Metadata\
  ..  (2) → obj\
  ..  (3) → src\solutions\{solutionName}\
  ..  (4) → src\solutions\
  ..  (5) → src\
           → webresources\{solutionAreaFolder}\WR-{Name}\dist
```

- `map` — path SolutionPackager expects inside the solution source (use `\` separators; matches the web resource logical name folder structure)
- If `map.xml` already exists, add a new `<FileToPath>` entry; never create a second `SolutionPackagerSwitches` property in the `.cdsproj`

### Which .cdsproj files need the map.xml reference?

Any solution that is built with `dotnet build` and needs to include the web resource must reference `map.xml` via `SolutionPackagerSwitches`. This includes **both**:

- The **feature solution** `.cdsproj` — used for inner-loop `dotnet build` + `pac solution import` to dev
- The **main solution** `.cdsproj` — used for outer-loop CI builds

If only the main solution has the reference, `dotnet build` on the feature solution will not find the compiled JS and the import will be missing the web resource.

## First-Time Metadata Registration

A web resource has two parts that must both exist in the solution source before Dataverse knows about it:

| Part | Handled by |
|------|------------|
| Compiled JS content | `map.xml` → copies `dist/{Name}.js` at pack time |
| Metadata declaration | `<WebResource>` entry in `customizations.xml` |

`map.xml` handles the content automatically at build time. The metadata must be added manually to `src/solutions/{mainSolution}/src/customizations.xml` inside the `<WebResources>` element:

```xml
<WebResource>
  <WebResourceId>{new-guid}</WebResourceId>
  <Name>{prefix}_/scripts/{Name}.js</Name>
  <DisplayName>{Name}</DisplayName>
  <Description/>
  <WebResourceType>3</WebResourceType>
  <IntroducedVersion>1.0.0.0</IntroducedVersion>
  <IsEnabledForMobileClient>0</IsEnabledForMobileClient>
  <IsAvailableForMobileOffline>0</IsAvailableForMobileOffline>
  <DependencyXml/>
  <IsCustomizable>
    <Value>1</Value>
    <CanBeChanged>1</CanBeChanged>
    <ManagedPropertyLogicalName>iscustomizable</ManagedPropertyLogicalName>
  </IsCustomizable>
  <CanBeDeleted>
    <Value>1</Value>
    <CanBeChanged>1</CanBeChanged>
    <ManagedPropertyLogicalName>canbedeleted</ManagedPropertyLogicalName>
  </CanBeDeleted>
  <IsHidden>
    <Value>0</Value>
    <CanBeChanged>1</CanBeChanged>
    <ManagedPropertyLogicalName>ishidden</ManagedPropertyLogicalName>
  </IsHidden>
  <IsManaged>0</IsManaged>
</WebResource>
```

- `{new-guid}` — generate a fresh GUID (e.g. `[System.Guid]::NewGuid()` in PowerShell)
- `WebResourceType` `3` = JavaScript
- `Name` must follow the logical name convention exactly: `{prefix}_/scripts/{Name}.js`

### Correct First-Time Workflow

```
1. Add <WebResource> entry to customizations.xml (above)
2. npm run build              ← compiles TypeScript → dist/{Name}.js
3. dotnet build               ← run from src/solutions/{featureSolutionName}/
                                 map.xml copies dist/{Name}.js into the solution ZIP
                                 output: obj/Debug/{featureSolutionName}.zip
4. pac solution import --path obj/Debug/{featureSolutionName}.zip \
     --environment {devEnvironmentUrl}   ← WR now exists in Dataverse (unmanaged)
5. Register the form event in the form designer (OnLoad → {Name}.onLoad)
6. pac solution sync to pull form customizations.xml changes back to source
```

> Do **not** create the web resource manually via make.powerapps.com first. Adding it directly to `customizations.xml` and deploying via the solution keeps the workflow code-first and avoids a portal round-trip.
>
> Do **not** create the solution ZIP manually. `dotnet build` handles packaging — the `map.xml` instructs it where to find the compiled JS. Never manually zip solution folders or call SolutionPackager directly.

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
4. **Add web resource metadata to `customizations.xml` directly** — do not create the web resource in make.powerapps.com first. Add the `<WebResource>` entry to the solution source, build and import the solution, then register the form event. See the First-Time Metadata Registration section for the XML template and workflow.
5. **`webResourcePreBuildPaths` must be updated** — CI will not build the web resource during outer-loop packaging unless the path is listed in `environment-config.json`.
6. **Do not commit `dist/`** — compiled output is generated during build and should be in `.gitignore`. The `map.xml` reference handles packaging at build time.
