---
applyTo: "src/controls/**"
---

# PCF Controls Development

## Project Layout

Controls are organized by solution under `src/controls/`:

| Solution | Notes |
|----------|-------|
| `{solutionPrefix}_{solutionName}/` | Read from `solutionAreas[].prefix` + `solutionAreas[].name` in `environment-config.json` |

Additional solution folders will appear here for multi-solution repos. Each control directory typically contains:
- `ControlManifest.Input.xml` — Component manifest (namespace, constructor, properties, resources)
- `*.pcfproj` — MSBuild project file
- `package.json` — npm dependencies
- `tsconfig.json` — TypeScript configuration
- `src/index.ts` — Entry point
- Optional: `jest.config.js`, `webpack.config.js`, `babel.config.js` for controls with custom build/test

## Workspace-Level Dependencies

Some controls use `file:` references in `package.json` to depend on other controls in the same repo. When modifying a control that others depend on, check for downstream impacts and install dependencies in the correct order (base controls first, then dependents).

## Test

Controls with Jest use this pattern (`jest.config.js`):

```javascript
module.exports = {
  preset: 'ts-jest',
  testEnvironment: 'jsdom',
  roots: ['<rootDir>/tests/'],
  transform: { '^.+\\.[t|j]sx?$': 'babel-jest' },
  setupFilesAfterEnv: ['./jest.setup.js'],
}
```

## ControlManifest.Input.xml

```xml
<manifest>
  <control namespace="{prefix}" constructor="{ControlName}" version="0.0.1" control-type="virtual">
    <data-set name="resultDataset" display-name-key="Dataset_Display_Key"/>
    <resources>
      <code path="index.ts" order="1"/>
      <platform-library name="React" version="16.8.6" />
      <platform-library name="Fluent" version="8.29.0" />
      <css path="css/{ControlName}.css" order="1" />
    </resources>
    <feature-usage>
      <uses-feature name="Utility" required="true" />
      <uses-feature name="WebAPI" required="true" />
    </feature-usage>
  </control>
</manifest>
```

- `control-type="virtual"` — React-based virtual controls (preferred for new controls)
- `control-type="standard"` — Legacy standard controls
- `namespace` must match the solution prefix (`slp`, `dot`, `vet`)

## Webpack Configuration

Controls with custom webpack (`webpack.config.js`) follow this pattern:

```javascript
module.exports = {
  entry: './src/index.ts',
  output: { path: 'dist', filename: 'index.js', libraryTarget: 'umd' },
  externals: { '@fluentui/react': 'FluentUIReact', 'react': 'React', 'react-dom': 'ReactDOM' },
  module: { rules: [{ test: /\.tsx?$/, use: 'ts-loader' }] },
}
```

Externals prevent React and FluentUI from being bundled (provided by the platform at runtime).

## Critical Rules

1. **PCF controls are NOT auto-tracked** — `pac pcf push` uses a temporary solution to import the PCF control so the PCF doesn't land in the preferred solution. You must build the feature solution and deploy it to the environment.
2. **`pac solution add-reference`** must be run once to wire the `.pcfproj` into the solution's `.cdsproj`
3. **Managed-layer controls** (those existing only in managed layer on dev org) cannot be synced via `pac solution sync` — bundles must be extracted from a managed export
4. **Namespace must match solution prefix**: use `solutionAreas[x].prefix` from `environment-config.json`
5. **`file:` dependencies** require install order: base controls first, then dependents

## Solution References

PCF controls wired into each solution `.cdsproj` are listed in `solutionAreas[x].controlPreBuildPaths` in `deployments/settings/environment-config.json`.
