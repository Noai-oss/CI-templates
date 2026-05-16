# CI Templates

Small, conservative GitHub Actions templates for Noai-oss repositories.

This repository is not meant to become a CI platform yet. For now it is a place
to keep the shared patterns visible, copyable, and only lightly reusable. Inputs
are added only when the current repositories already need a real difference.

## Current Inventory

Checked on 2026-05-16.

This inventory covers the existing project repositories that motivated these
templates. The `CI-templates` repository itself keeps reusable workflow files
with a leading `_` so they are easy to distinguish from normal entrypoint
workflows.

| Repository | Existing workflows | Notes |
| --- | --- | --- |
| [Noai-oss/fonti](https://github.com/Noai-oss/fonti) | none | Python `uv` project. Windows-only runtime dependency (`pywin32`), so CI should run on `windows-latest`. |
| [Noai-oss/O.Ps](https://github.com/Noai-oss/O.Ps) | none | PowerShell module with pre-commit hooks and a `build.ps1` pre-commit build step. Keep local until another PowerShell repository repeats the pattern. |
| [Noai-oss/uvg](https://github.com/Noai-oss/uvg/tree/main/.github/workflows) | `ci-test.yml`, `lock-upgrade.yml`, `pr-title-check.yml` | Python `uv` project. CI runs on Ubuntu and Windows. |
| [Noai-oss/odev](https://github.com/Noai-oss/odev/tree/main/.github/workflows) | `ci-test.yml`, `lock-upgrade.yml`, `pr-title-check.yml`, `readme-update.yml` | Python `uv` project. CI runs on Ubuntu only. `readme-update.yml` is repo-specific and is not extracted yet. |

## Current Position

Use this repository as a template source first. Switch a repository to reusable
workflows only when the indirection is cheaper than keeping a local YAML file.

Good reasons to use `uses: Noai-oss/CI-templates/...@main`:

- The same workflow exists in at least two repositories.
- Updates to action versions or command order are becoming repetitive.
- The workflow does not need repo-specific logic.

Good reasons to keep a local workflow:

- Only one repository uses it.
- The workflow has project-specific text replacement, release logic, or paths.
- The reusable workflow would need several speculative inputs to fit it.

## Reusable Workflows

Reusable workflow files in this repository use a leading `_`:

- `_python-uv-ci.yml`
- `_uv-lock-upgrade.yml`
- `_pr-title-check.yml`

Normal workflow files without `_` are entrypoints for this repository itself or
for consuming repositories. For example, this repository's
`.github/workflows/pr-title-check.yml` calls `_pr-title-check.yml` through:

```yaml
jobs:
  check-title:
    uses: ./.github/workflows/_pr-title-check.yml
```

### `_python-uv-ci.yml`

Reusable replacement for the duplicated `CI Test` workflows in `uvg` and
`odev`, and a ready fit for `fonti`.

The only input is `os_matrix`, because that is the only CI difference currently
seen across the Python `uv` repositories.

```yaml
name: CI Test

on:
  push:
    branches: [main]
  pull_request:
    branches: [main]

jobs:
  ci-test:
    uses: Noai-oss/CI-templates/.github/workflows/_python-uv-ci.yml@main
```

For `uvg`, preserve the current OS matrix:

```yaml
jobs:
  ci-test:
    uses: Noai-oss/CI-templates/.github/workflows/_python-uv-ci.yml@main
    with:
      os_matrix: '["ubuntu-latest","windows-latest"]'
```

For `fonti`, start with Windows only:

```yaml
jobs:
  ci-test:
    uses: Noai-oss/CI-templates/.github/workflows/_python-uv-ci.yml@main
    with:
      os_matrix: '["windows-latest"]'
```

### `_uv-lock-upgrade.yml`

Reusable replacement for the weekly `uv.lock` upgrade workflows in `uvg` and
`odev`.

```yaml
name: Lock Upgrade

on:
  schedule:
    - cron: "0 0 * * 0"
  workflow_dispatch:

permissions:
  contents: write
  pull-requests: write

jobs:
  lock-upgrade:
    uses: Noai-oss/CI-templates/.github/workflows/_uv-lock-upgrade.yml@main
    secrets:
      PAT: ${{ secrets.PAT }}
```

### `_pr-title-check.yml`

Reusable replacement for PR title validation. By default it uses the same pinned
`odev` commit used by the current repositories.

```yaml
name: PR Title Check

on:
  pull_request:
    types: [opened, edited, synchronize]

jobs:
  check-title:
    uses: Noai-oss/CI-templates/.github/workflows/_pr-title-check.yml@main
```

For `odev` itself, use the local project instead:

```yaml
jobs:
  check-title:
    uses: Noai-oss/CI-templates/.github/workflows/_pr-title-check.yml@main
    with:
      checker_source: .
```

## Not Extracted Yet

`odev/.github/workflows/readme-update.yml` updates the commit hash embedded in
`odev`'s own README. It should stay local until another repository needs the
same "update a pinned README reference and open a PR" pattern.

`O.Ps` should get a separate reusable workflow only if the PowerShell
build/check pattern appears in another repository. A first version would likely
run `pwsh -File build.ps1`, pre-commit hooks, and optional Pester tests.
