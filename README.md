# {{CLIENT_NAME}} Platform Repository

{{PRODUCT_DESCRIPTION}}

## Quick Start

See [SETUP.md](SETUP.md) for initial configuration steps after cloning this template.

## Repository Structure

```
src/
  controls/     # PCF (PowerApps Component Framework) controls
  plugins/      # .NET plugin assemblies
  solutions/    # Unpacked Dataverse solution metadata (.cdsproj)
deployments/
  settings/     # Deployment configuration (environment-config.json, mappings, etc.)
  data/         # Configuration data for post-deploy import
.github/
  workflows/    # GitHub Actions thin-caller workflows
  instructions/ # Copilot coding instructions
```

## Branching Strategy

```
main (production-ready, protected)
 ↑ PR from develop or hotfix/* only
develop (integration branch)
 ↑ PR from feature branches / transport commits
feature/AB<N>_Description   (branch from develop)
hotfix/<issue-number>        (branch from main → merge to both main + develop)
```

## CI/CD

All workflows are **thin callers** — they delegate to
`{{GITHUB_ORG}}/Agentic-ALM-Workflows`
and only contain `on:` triggers and `uses:` references.
Scripts and reusable jobs live in Agentic-ALM-Workflows.

| Workflow | Trigger | Purpose |
|----------|---------|---------|
| `sync-solution.yml` | Manual | Export solution from Dataverse to repo |
| `build-deploy-solution.yml` | Manual | Build → Deploy (inner loop, no sync) |
| `sync-build-deploy-solution.yml` | Manual | Sync → Build → Deploy |
| `transport-solution.yml` | Manual | Transport dev → integration |
| `deploy-package.yml` | Manual | Deploy release package to an environment |
| `deploy-solutions.yml` | Manual / after release | Deploy individual solutions from a release |
| `create-release-package.yml` | Push to `main` / manual | Build release packages + create GitHub Release |
| `pr-validation.yml` | Pull request | Build and validate changed components |
| `check-source-branch.yml` | Pull request | Enforce branch policies |
