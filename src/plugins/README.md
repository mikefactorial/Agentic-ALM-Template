# src\plugins

Place Plugin source code here, organized by solution area:

```
src/
  controls/         # PCF (PowerApps Component Framework) TypeScript controls
    {solutionPrefix}_{solutionName}/  # read from solutionAreas[] in deployments/settings/environment-config.json
  plugins/          # C# .NET plugin assemblies
    {solutionPrefix}_{solutionName}/
  solutions/        # Unpacked Dataverse solution metadata (.cdsproj)
    {solutionPrefix}_{solutionName}/
```

See the Copilot instructions and skills for scaffolding commands.
