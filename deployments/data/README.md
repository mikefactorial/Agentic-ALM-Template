# Configuration Migration Data

This directory contains configuration data imported into each environment after solution deployment.

## Structure

Data is organized by solution name — one subfolder per solution that has migration data:

```
deployments/data/
  {prefix}_{SolutionName}/     # e.g. acm_AcmePlatform
    data.xml                   # Configuration data exported via pac data export
    data_schema.xml            # Schema file describing the entities and fields
```

## Purpose

These files are used by the Package Deployer to seed or update configuration records (e.g. environment-specific settings, reference data, admin configuration) after each solution import. Data is imported in the order defined by `PkgAssets/ImportConfig.xml`.

## Adding Data for a Solution

1. Export configuration data from your source environment:
   ```powershell
   pac data export --schema-file deployments/data/{prefix}_{SolutionName}/data_schema.xml `
                   --data-file   deployments/data/{prefix}_{SolutionName}/data.xml `
                   --environment <environment-url>
   ```
2. Commit both files to the feature branch.
3. The Package Deployer will import the data automatically on the next deployment.
