---
applyTo: "src/codeapps/**"
---

# Code App Development

## Project Layout

Code apps are organized by solution under `src/codeapps/`:

| Solution | Notes |
|----------|-------|
| `{solutionPrefix}_{solutionName}/` | Read from `solutionAreas[].prefix` + `solutionAreas[].name` in `environment-config.json` |

Each app directory uses the app name directly (no prefix convention) and typically contains:
- `src/App.tsx` — Root React component
- `src/main.tsx` — Entry point
- `vite.config.ts` — Build configuration (must disable content hashing — see Critical Rules)
- `package.json` — npm dependencies
- `tsconfig.json` — TypeScript configuration
- `power.config.json` — Created by `pac code init`; links the project to the Dataverse app record
- `dist/` — Compiled static assets (generated; not committed to source control)

## When to Use a Code App

| Scenario | Use |
|----------|-----|
| Standalone web app hosted in Power Apps | Code app |
| Needs Power Platform connectors (Dataverse, SharePoint, custom APIs) | Code app |
| Rich React UI that goes beyond what a form field allows | Code app |
| Custom UI component embedded on a model-driven form | PCF control (`src/controls/`) |
| Form/ribbon script logic (OnLoad, OnChange) | Web resource (`src/webresources/`) |

## Prerequisites

- **Admin must enable code apps** on each target environment: Settings > Product > Features > Power Apps code apps
- **End users need a Power Apps Premium license** to run code apps
- `pac` CLI and Node.js LTS must be installed locally

## Naming Conventions

| Element | Convention | Example |
|---------|-----------|---------|
| Directory | `{AppName}/` — PascalCase, descriptive | `ContractReview/` |
| Dataverse logical name | `{prefix}_{appname}_{hash}` — assigned by `pac code init` | `acm_contractreview_4a3f2` |
| map.xml folder mapping | `CanvasApps\{logicalName}_CodeAppPackages` | See map.xml section |

> The Dataverse logical name is assigned by `pac code init` and revealed by `pac solution sync`. It cannot be known before running those commands.

## Vite Build Requirements

Code apps MUST disable Vite content hashing so `meta.xml` can reference stable filenames. Key requirements in `vite.config.ts`:

```typescript
build: {
  rollupOptions: {
    output: {
      entryFileNames: 'assets/index.js',     // no hash
      chunkFileNames: 'assets/[name].js',
      assetFileNames: 'assets/[name][extname]',
    },
  },
}
```

Expected `dist/` output: `index.html`, `assets/index.js`, `assets/index.css` — no hash suffixes.

## map.xml Wiring

Code apps use a `<Folder>` mapping (not `<FileToPath>`) because the entire `_CodeAppPackages/` directory tree must be mapped:

```xml
<Folder
  map="CanvasApps\{logicalName}_CodeAppPackages"
  to="..\..\..\codeapps\{solutionAreaFolder}\{AppName}\dist" />
```

- `map` — the `_CodeAppPackages` folder name as it appears in the solution source after sync
- `to` — relative to `src/solutions/{mainSolution}/src/` (three `..` levels up reaches `src/`)
- `{logicalName}` is determined after `pac code init` + `pac solution sync` — it cannot be guessed
- If `map.xml` already exists, add a new `<Folder>` entry; never create a second `SolutionPackagerSwitches` property in the `.cdsproj`

## meta.xml Maintenance

After the first `pac solution sync`, verify `{logicalName}.meta.xml` in the solution source references static (non-hashed) filenames:

```xml
<CodeAppPackageUris>
  <CodeAppPackageUri>/CanvasApps/{logicalName}_CodeAppPackages/index.html_ContentType_text/html</CodeAppPackageUri>
  <CodeAppPackageUri>/CanvasApps/{logicalName}_CodeAppPackages/assets/index.js_ContentType_application/javascript</CodeAppPackageUri>
  <CodeAppPackageUri>/CanvasApps/{logicalName}_CodeAppPackages/assets/index.css_ContentType_text/css</CodeAppPackageUri>
</CodeAppPackageUris>
```

If the filenames contain Vite content hashes, correct them to match the static names configured in `vite.config.ts` and commit the corrected file. This file only needs updating when output filenames change (which they won't, since hashing is disabled).

## Inner Loop Development

```
1. npm run dev         — local Vite dev server with Power Platform connection proxy
2. Open the "Local Play" URL in the same browser profile as your Power Platform tenant
3. Iterate locally
4. npm run build
5. pac code push --solutionName {featureSolutionName} --environment {devEnvironmentUrl}
6. Test the deployed version in Power Platform
```

> Resolve `{devEnvironmentUrl}` from `innerLoopEnvironments[]` using `solutionAreas[x].devEnv` as the slug.

## environment-config.json Reference

| Field | Purpose |
|-------|---------|
| `solutionAreas[x].prefix` | Publisher prefix |
| `solutionAreas[x].cdsproj` | Solution `.cdsproj` for `map.xml` wiring |
| `solutionAreas[x].mainSolution` | Solution name for `pac code push --solutionName` and map.xml path |
| `solutionAreas[x].devEnv` | Slug for the dev inner-loop environment |
| `innerLoopEnvironments[].url` | Resolve the dev environment URL from the slug |
| `solutionAreas[x].codeAppPreBuildPaths` | Paths read by `Build-CodeApps.ps1` during CI — append here when adding a new app |

## Critical Rules

1. **Use `pac code init` to initialize** — never use `pac code push --displayName` for the first push; it may silently omit the solution association. Always run `pac code init` first, then `pac code push`.
2. **No content hashing** — `meta.xml` references specific filenames. If Vite generates hashed names, the solution packager will not find the assets and the build will fail silently.
3. **`{logicalName}` comes from sync** — run `pac solution sync` after `pac code init` to discover the assigned logical name before writing `map.xml`.
4. **Use `<Folder>` in map.xml, not `<FileToPath>`** — code apps map an entire directory tree, not a single file. Using `<FileToPath>` will silently exclude all but one asset.
5. **`pac code push` is the inner-loop deploy** — do not use `pac solution import` to deploy code app changes; use `pac code push` so assets are updated correctly in Dataverse.
6. **`codeAppPreBuildPaths` must be updated** — CI will not build the app during outer-loop packaging unless the path is listed in `environment-config.json`.
7. **Code apps require admin enablement per environment** — the feature toggle must be on before any code app can run, including in dev-test, test, and prod.
