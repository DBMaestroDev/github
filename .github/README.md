# GitHub Actions Workflows and Composite Actions

This repository contains reusable workflows and composite actions for DBmaestro package management and environment upgrades. The workflows and actions are available in two variants: **Linux** (bash) and **PowerShell** (Windows).

**Note:** The composite actions referenced by these workflows are located in the `DBMaestroDev/github` repository and are called using the `@v1` branch reference (e.g., `DBMaestroDev/github/.github/actions/sh/detect-changed-packages@v1`).

## Table of Contents

- [Workflows](#workflows)
  - [Linux Workflows](#sh-workflows)
  - [PowerShell Workflows](#ps-workflows)
- [Composite Actions](#composite-actions)
  - [Linux Actions](#sh-actions)
  - [PowerShell Actions](#ps-actions)
- [Usage](#usage)

---

## Workflows

### Linux Workflows

#### 1. Build and Validate Packages
**File:** `.github/workflows/sh-build-validate.yml`

A reusable workflow for building and validating DBmaestro packages on Linux runners.

**Features:**
- Builds packages from a JSON matrix input
- Validates packages using precheck operation
- Sequential execution (max-parallel: 1)
- Supports both hosted and self-hosted runners

**Key Inputs:**
- `project-name`: DBmaestro project name (required)
- `packages-matrix`: JSON array of packages to build (required)
- `packages-folder`: Root folder containing packages (default: `packages`)
- `agent-jar-path`: Path to DBmaestro agent JAR file (default: `/home/runner/DBmaestroAgent.jar`)
- `use-ssl`: Use SSL for DBmaestro connection (default: `True`)
- `auth-type`: Authentication type (default: `DBmaestroAccount`)
- `package-type`: Package type - Regular or AdHoc (default: `Regular`)
- `runner`: Runner type (default: `ubuntu-latest`)

**Required Secrets:**
- `dbmaestro-server`: DBmaestro server hostname (Format: `AGENT_DNS:PORT`, e.g., `agent01.dbmaestro.local:8017`)
- `dbmaestro-user`: DBmaestro username
- `dbmaestro-password`: DBmaestro password or token

**Jobs:**
- `create_package`: Creates DBmaestro packages from folders
- `validate_package`: Validates packages using precheck operation

---

#### 2. Upgrade Environment (Linux)
**File:** `.github/workflows/sh-upgrade-environment.yml`

A reusable workflow for upgrading DBmaestro environments on Linux runners.

**Features:**
- Manual package input or automatic detection from git changes
- Pull request support with automatic package detection
- Sequential upgrade execution (max-parallel: 1)
- PR comment posting with detected packages
- GitHub job summaries with upgrade details

**Key Inputs:**
- `package_name`: Comma-separated list of packages (optional)
- `target_environment`: Target environment for upgrade (required)
- `project_name`: DBmaestro project name (default: `Demo-PSQL`)
- `agent_jar_path`: Path to DBmaestro Agent JAR (default: `/opt/dbmaestro/agent/DBmaestroAgent.jar`)
- `use_ssl`: Use SSL for connection (default: `True`)
- `auth-type`: Authentication type (default: `DBmaestroAccount`)
- `detect_from_push`: Detect packages from git push (default: `false`)
- `is_pull_request`: Whether this is a PR event (default: `false`)
- `runner`: Runner type (default: `ubuntu-latest`)

**Required Secrets:**
- `DBMAESTRO_SERVER`: DBmaestro server URL (Format: `AGENT_DNS:PORT`, e.g., `agent01.dbmaestro.local:8017`)
- `DBMAESTRO_USER`: DBmaestro username
- `DBMAESTRO_PASSWORD`: DBmaestro password

**Outputs:**
- `upgraded_packages`: List of packages that were upgraded

**Jobs:**
- `detect_changed_packages`: Detects packages from manual input or git push
- `detect_changed_packages_pr`: Detects packages from pull request changes
- `post_pr_comment`: Posts PR comment with detected packages (PR only)
- `upgrade_environment`: Performs the actual environment upgrade

---

### PowerShell Workflows

#### 1. Upgrade Environment (PowerShell)
**File:** `.github/workflows/ps-upgrade-environment.yml`

A reusable workflow for upgrading DBmaestro environments using PowerShell on Windows runners.

**Features:**
- Manual package input or automatic detection from git changes
- Pull request support with automatic package detection
- Sequential upgrade execution (max-parallel: 1)
- PR comment posting with detected packages
- Uses self-hosted Windows runners by default

**Key Inputs:**
- `package_name`: Comma-separated list of packages (optional)
- `target_environment`: Target environment for upgrade (required)
- `project_name`: DBmaestro project name (default: `Demo-PSQL`)
- `agent_jar_path`: Path to DBmaestro Agent JAR (default: `C:\Program Files (x86)\DBmaestro\DOP Server\Agent\DBmaestroAgent.jar`)
- `use_ssl`: Use SSL for connection (default: `True`)
- `auth-type`: Authentication type (default: `DBmaestroAccount`)
- `detect_from_push`: Detect packages from git push (default: `false`)
- `is_pull_request`: Whether this is a PR event (default: `false`)

**Required Secrets:**
- `DBMAESTRO_SERVER`: DBmaestro server URL (Format: `AGENT_DNS:PORT`, e.g., `agent01.dbmaestro.local:8017`)
- `DBMAESTRO_USER`: DBmaestro username
- `DBMAESTRO_PASSWORD`: DBmaestro password

**Outputs:**
- `upgraded_packages`: List of packages that were upgraded

**Jobs:**
- `detect_changed_packages`: Detects packages from manual input or git push
- `detect_changed_packages_pr`: Detects packages from pull request changes
- `post_pr_comment`: Posts PR comment with detected packages (PR only)
- `upgrade_environment`: Performs the actual environment upgrade

---

## Composite Actions

### Linux Actions

All Linux actions use bash scripts and are located in the `DBMaestroDev/github` repository at `.github/actions/sh/`.

#### 1. Create Package
**Location:** `DBMaestroDev/github/.github/actions/sh/create-package/action.yml`

Creates a DBmaestro package from a folder with manifest, tar archive, and package creation.

**Inputs:**
- `package-name`: Name of the package to create (required)
- `project-name`: DBmaestro project name (required)
- `packages-folder`: Root folder containing packages (default: `packages`)
- `agent-jar-path`: Path to DBmaestro agent JAR file (required)
- `dbmaestro-server`: DBmaestro server hostname (required) - Format: `AGENT_DNS:PORT`, e.g., `agent01.dbmaestro.local:8017`
- `use-ssl`: Use SSL for connection (default: `True`)
- `auth-type`: Authentication type (default: `DBmaestroAccount`)
- `username`: DBmaestro username (required)
- `password`: DBmaestro password or token (required)
- `package-type`: Package type - Regular or AdHoc (default: `Regular`)
- `ignore-script-warnings`: Ignore script warnings (default: `True`)

**Outputs:**
- `package-created`: Whether package was created successfully

**Steps:**
1. Validates package folder exists
2. Creates manifest and tar archive
3. Executes DBmaestro package creation via Java agent

---

#### 2. Precheck Package
**Location:** `DBMaestroDev/github/.github/actions/sh/precheck-package/action.yml`

Validates a DBmaestro package using precheck operation.

**Inputs:**
- `package-name`: Name of the package to validate (required)
- `project-name`: DBmaestro project name (required)
- `agent-jar-path`: Path to DBmaestro agent JAR file (required)
- `dbmaestro-server`: DBmaestro server hostname (required) - Format: `AGENT_DNS:PORT`, e.g., `agent01.dbmaestro.local:8017`
- `use-ssl`: Use SSL for connection (default: `True`)
- `auth-type`: Authentication type (default: `DBmaestroAccount`)
- `username`: DBmaestro username (required)
- `password`: DBmaestro password or token (required)

**Outputs:**
- `validation-passed`: Whether validation passed

**Steps:**
1. Runs precheck validation via DBmaestro agent

---

#### 3. Detect Changed Packages
**Location:** `DBMaestroDev/github/.github/actions/sh/detect-changed-packages/action.yml`

Detects changed packages from git commits or manual input using bash scripts.

**Inputs:**
- `package_name`: Comma-separated package names (optional)
- `detect_from_push`: Detect from git push (default: `false`)
- `is_pull_request`: Whether this is a PR event (default: `false`)
- `base_ref`: Base reference for PR comparison (optional)

**Outputs:**
- `matrix`: JSON matrix for packages
- `has-packages`: Whether packages were detected
- `packages`: JSON array of packages
- `packages-list`: Comma-separated list of packages

**Detection Sources:**
1. Manual comma-separated input
2. Git diff from push events
3. Git diff from pull requests

---

#### 4. Upgrade Environment
**Location:** `DBMaestroDev/github/.github/actions/sh/upgrade-environment/action.yml`

Upgrades a target environment with a specific package using DBmaestro on Linux.

**Inputs:**
- `package_name`: Package name to upgrade (required)
- `target_environment`: Target environment (required)
- `project_name`: DBmaestro project name (required)
- `agent_jar_path`: Path to DBmaestro Agent JAR (required)
- `use_ssl`: Use SSL (default: `True`)
- `dbmaestro_server`: DBmaestro server URL (required) - Format: `AGENT_DNS:PORT`, e.g., `agent01.dbmaestro.local:8017`
- `dbmaestro_user`: DBmaestro username (required)
- `dbmaestro_password`: DBmaestro password (required)
- `auth_type`: Authentication type (default: `DBmaestroAccount`)

**Steps:**
1. Normalizes environment name (replaces underscores with spaces)
2. Creates GitHub step summary with upgrade details
3. Executes Java-based DBmaestro agent upgrade command
4. Handles errors with appropriate exit codes

---

#### 5. PR Comment
**Location:** `DBMaestroDev/github/.github/actions/sh/pr-comment/action.yml`

Posts a comment on a pull request with detected package information.

**Inputs:**
- `packages_list`: Comma-separated list of detected packages (required)
- `environment_name`: Target environment name (required)
- `github_token`: GitHub token for API access (required)

**Steps:**
1. Posts formatted comment to PR using GitHub Script API

**Comment Format:**
```
## 📦 Changed Packages Detected

**Modified Packages:** [package list]

This pull request affects the following packages in the `/packages` folder.
Will upgrade **[environment]** with these packages (in order) upon merging.
```

---

### PowerShell Actions

All PowerShell actions use PowerShell scripts and are located in the `DBMaestroDev/github` repository at `.github/actions/ps/`.

#### 1. Detect Changed Packages
**Location:** `DBMaestroDev/github/.github/actions/ps/detect-changed-packages/action.yml`

Detects changed packages from git commits or manual input using PowerShell.

**Inputs:**
- `package_name`: Comma-separated package names (optional)
- `detect_from_push`: Detect from git push (default: `false`)
- `is_pull_request`: Whether this is a PR event (default: `false`)
- `base_ref`: Base reference for PR comparison (optional)

**Outputs:**
- `matrix`: JSON matrix for packages
- `has-packages`: Whether packages were detected
- `packages`: JSON array of packages
- `packages-list`: Comma-separated list of packages

**Detection Sources:**
1. Manual comma-separated input
2. Git diff from push events
3. Git diff from pull requests

---

#### 2. Upgrade Environment
**Location:** `DBMaestroDev/github/.github/actions/ps/upgrade-environment/action.yml`

Upgrades a target environment with a specific package using DBmaestro on Windows.

**Inputs:**
- `package_name`: Package name to upgrade (required)
- `target_environment`: Target environment (required)
- `project_name`: DBmaestro project name (required)
- `agent_jar_path`: Path to DBmaestro Agent JAR (required)
- `use_ssl`: Use SSL (default: `True`)
- `dbmaestro_server`: DBmaestro server URL (required) - Format: `AGENT_DNS:PORT`, e.g., `agent01.dbmaestro.local:8017`
- `dbmaestro_user`: DBmaestro username (required)
- `dbmaestro_password`: DBmaestro password (required)
- `auth_type`: Authentication type (default: `DBmaestroAccount`)

**Steps:**
1. Normalizes environment name (replaces underscores with spaces)
2. Creates GitHub step summary with upgrade details
3. Executes Java-based DBmaestro agent upgrade command
4. Handles errors with appropriate exit codes

---

#### 3. PR Comment
**Location:** `DBMaestroDev/github/.github/actions/ps/pr-comment/action.yml`

Posts a comment on a pull request with detected package information (identical to Linux version).

**Inputs:**
- `packages_list`: Comma-separated list of detected packages (required)
- `environment_name`: Target environment name (required)
- `github_token`: GitHub token for API access (required)

**Steps:**
1. Posts formatted comment to PR using GitHub Script API

---

## Usage

### Example: Calling the Linux Build and Validate Workflow

```yaml
name: Build Packages

on:
  workflow_dispatch:
    inputs:
      packages:
        description: 'Packages to build (JSON array)'
        required: true

jobs:
  build:
    uses: DBMaestroDev/github/.github/workflows/sh-build-validate.yml@v1
    with:
      project-name: 'MyProject'
      packages-matrix: ${{ github.event.inputs.packages }}
      runner: 'ubuntu-latest'
    secrets:
      dbmaestro-server: ${{ secrets.DBMAESTRO_SERVER }}
      dbmaestro-user: ${{ secrets.DBMAESTRO_USER }}
      dbmaestro-password: ${{ secrets.DBMAESTRO_PASSWORD }}
```

### Example: Calling the Linux Upgrade Workflow with Manual Packages

```yaml
name: Manual Upgrade

on:
  workflow_dispatch:
    inputs:
      packages:
        description: 'Packages to upgrade (comma-separated)'
        required: true
      environment:
        description: 'Target environment'
        required: true

jobs:
  upgrade:
    uses: DBMaestroDev/github/.github/workflows/sh-upgrade-environment.yml@v1
    with:
      package_name: ${{ github.event.inputs.packages }}
      target_environment: ${{ github.event.inputs.environment }}
      project_name: 'Demo-PSQL'
    secrets:
      DBMAESTRO_SERVER: ${{ secrets.DBMAESTRO_SERVER }}
      DBMAESTRO_USER: ${{ secrets.DBMAESTRO_USER }}
      DBMAESTRO_PASSWORD: ${{ secrets.DBMAESTRO_PASSWORD }}
```

### Example: Calling the Upgrade Workflow on Push (Auto-Detect)

```yaml
name: Auto Upgrade on Push

on:
  push:
    branches:
      - main
    paths:
      - 'packages/**'

jobs:
  upgrade:
    uses: DBMaestroDev/github/.github/workflows/sh-upgrade-environment.yml@v1
    with:
      target_environment: 'Development'
      project_name: 'Demo-PSQL'
      detect_from_push: true
    secrets:
      DBMAESTRO_SERVER: ${{ secrets.DBMAESTRO_SERVER }}
      DBMAESTRO_USER: ${{ secrets.DBMAESTRO_USER }}
      DBMAESTRO_PASSWORD: ${{ secrets.DBMAESTRO_PASSWORD }}
```

### Example: Calling the Upgrade Workflow on Pull Request

```yaml
name: Upgrade on PR

on:
  pull_request:
    branches:
      - main
    paths:
      - 'packages/**'

jobs:
  upgrade:
    uses: DBMaestroDev/github/.github/workflows/sh-upgrade-environment.yml@v1
    with:
      target_environment: 'QA'
      project_name: 'Demo-PSQL'
      is_pull_request: true
    secrets:
      DBMAESTRO_SERVER: ${{ secrets.DBMAESTRO_SERVER }}
      DBMAESTRO_USER: ${{ secrets.DBMAESTRO_USER }}
      DBMAESTRO_PASSWORD: ${{ secrets.DBMAESTRO_PASSWORD }}
```

### Example: Using Composite Actions Directly

```yaml
- name: Detect Packages
  id: detect
  uses: DBMaestroDev/github/.github/actions/sh/detect-changed-packages@v1
  with:
    package_name: 'V15,V16'
    detect_from_push: false

- name: Upgrade Environment
  uses: DBMaestroDev/github/.github/actions/sh/upgrade-environment@v1
  with:
    package_name: 'V15'
    target_environment: 'Production'
    project_name: 'MyProject'
    agent_jar_path: '/opt/dbmaestro/agent/DBmaestroAgent.jar'
    dbmaestro_server: ${{ secrets.DBMAESTRO_SERVER }}
    dbmaestro_user: ${{ secrets.DBMAESTRO_USER }}
    dbmaestro_password: ${{ secrets.DBMAESTRO_PASSWORD }}
```

---

## Key Differences: Linux vs PowerShell

| Feature | Linux | PowerShell |
|---------|-------|------------|
| **Shell** | bash | PowerShell |
| **Default Runner** | `ubuntu-latest` (configurable) | `self-hosted` |
| **Agent Path** | `/opt/dbmaestro/agent/DBmaestroAgent.jar` | `C:\Program Files (x86)\DBmaestro\DOP Server\Agent\DBmaestroAgent.jar` |
| **Additional Workflows** | Build and Validate | (not available) |
| **Additional Actions** | Create Package, Precheck Package | (not available) |

---

## Required Secrets

All workflows require the following secrets to be configured:

- `DBMAESTRO_SERVER` or `dbmaestro-server`: DBmaestro server hostname/URL
  - Format: `AGENT_DNS:PORT` (Example: `agent01.dbmaestro.local:8017`)
- `DBMAESTRO_USER` or `dbmaestro-user`: DBmaestro username
- `DBMAESTRO_PASSWORD` or `dbmaestro-password`: DBmaestro password or API token

For PR comments, `GITHUB_TOKEN` is automatically provided by GitHub Actions.

---

## Notes

- **Sequential Execution**: All upgrade jobs use `max-parallel: 1` to ensure packages are upgraded in order
- **Environment Name Normalization**: Both Linux and PowerShell actions automatically replace underscores with spaces in environment names
- **Package Detection**: Packages are detected from the `packages/` folder root directory
- **Runner Requirements**: Linux workflows can run on `ubuntu-latest` or self-hosted runners; PowerShell workflows require Windows runners
