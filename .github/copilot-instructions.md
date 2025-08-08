# Symphony - Infrastructure as Code Framework

Symphony is an enterprise-level CI/CD multi-orchestrator framework for developing, testing, and deploying Infrastructure as Code (IaC) on Azure using Terraform and Bicep. It provides automated testing, security scanning, multi-environment deployments, and best practices for IaC development.

Always reference these instructions first and fallback to search or bash commands only when you encounter unexpected information that does not match the info here.

## Working Effectively

### Bootstrap and Setup the Repository
- Clone and setup Symphony CLI:
  - `git clone https://github.com/microsoft/symphony.git && cd symphony`
  - `source setup.sh` -- adds Symphony CLI to PATH temporarily (~0.001s)
  - `symphony --help` -- validates CLI is working (~12s including dependency checks)

### Prerequisites and Dependencies
- **CRITICAL**: Install these exact dependencies before proceeding:
  - Git (version 2.40.0 or newer): `git --version` 
  - Azure CLI: `az version` -- currently requires version 2.75.0+
  - JQ: `jq --version` -- required for JSON processing
  - sed: `sed --version` -- required for text processing
  - **For Terraform**: Go 1.16+ for testing: `go version`
  - **For Bicep**: PowerShell 7+ for testing: `pwsh --version`

### Install Build Tools (NEVER CANCEL - Set timeout 600s+)
- Install Terraform: `cd scripts/orchestrators && ./setup-terraform.sh` -- takes ~2s, downloads and installs latest Terraform
- Install Go (if not present): `./setup-go.sh` -- takes ~60s if downloading, includes common Go tools
- Install TFLint: `./setup-tflint.sh` -- takes ~2s, downloads TFLint v0.58.1+
- Install Bicep tools: `./setup-bicep.sh` -- instant if already installed via Azure CLI
- Install ARM TTK: `./setup-armttk.sh` -- takes ~6s, downloads ARM Template Toolkit for PowerShell

### Build and Validation (NEVER CANCEL - Set timeout 1800s+)
- **Terraform Linting**: 
  - `cd scripts/orchestrators && export WORKSPACE_PATH=$(pwd)/../.. && ./iac.tf.lint.sh` -- takes ~0.2s, lints all Terraform modules with TFLint
  - **NEVER CANCEL**: Runs TFLint on all Terraform modules sequentially
- **Bicep Linting**:
  - `cd scripts/orchestrators && export WORKSPACE_PATH=$(pwd)/../.. && ./iac.bicep.lint.sh` -- takes ~59s, runs Bicep lint + ARM TTK
  - **NEVER CANCEL**: ARM TTK validation can take 45-60 seconds. Set timeout to 1800s minimum.
- **MegaLinter** (comprehensive linting):
  - `docker run --rm -v $(pwd):/tmp/lint oxsecurity/megalinter:v8 --flavor cupcake --env LOG_LEVEL=INFO --env GITHUB_WORKSPACE=/tmp/lint`
  - **NEVER CANCEL**: Takes 45+ seconds, may have network timeouts but completes successfully. Set timeout to 1800s.

### Testing (NEVER CANCEL - Set timeout 1800s+) 
- **Terraform Unit Tests**: 
  - `cd IAC/Terraform/test/terraform && go test -v -timeout 300s --tags=module_test` -- takes ~90s for dependency download + test execution
  - **NEVER CANCEL**: First run downloads Terratest dependencies (90+ seconds). Subsequent runs are faster.
- **Terraform E2E Tests**:
  - `cd IAC/Terraform/test/terraform && go test -v -timeout 1000s --tags=e2e_test`
  - **NOTE**: Requires Azure authentication and deployed resources. Will fail without proper setup.
- **Bicep Tests**:
  - ARM TTK tests run automatically during `./iac.bicep.lint.sh`
  - Pester tests: Install with `Install-Module -Name Pester -AllowClobber -Force -Confirm:$False -SkipPublisherCheck` then `Invoke-Pester -Path ./pester/End_To_End.Tests.ps1`

## Symphony CLI Operations

### Provision Azure Dependencies (Azure Authentication Required)
- **CRITICAL**: Must run `az login` and `az account set --subscription <SubscriptionId>` first
- `symphony provision` -- **NEVER CANCEL**: Takes 5-15 minutes, prompts for Azure location and Terraform choice
- Creates: Resource Group, Key Vault, Service Principal, Storage Accounts (for Terraform state)

### Configure CI/CD Pipeline
- `symphony pipeline config <azdo|github> <terraform|bicep>`
- Examples:
  - `symphony pipeline config github terraform`
  - `symphony pipeline config azdo bicep`
- **NEVER CANCEL**: Takes 10-30 minutes, creates repository, configures workflows/pipelines, pushes code

### Destroy Symphony Resources  
- `symphony destroy` -- **CRITICAL**: Destructive operation, removes all Symphony-provisioned Azure resources

## Validation Scenarios

### Manual Testing Requirements
**ALWAYS** run these validation scenarios after making changes:

#### Terraform Development Flow
1. **Setup Validation**: `source setup.sh && symphony --help` - verify CLI works
2. **Code Validation**: `cd scripts/orchestrators && export WORKSPACE_PATH=$(pwd)/../.. && ./iac.tf.lint.sh` - verify linting passes
3. **Direct Terraform Test**: 
   - `cd IAC/Terraform/terraform/01_init && terraform init -backend=false && terraform validate`
   - Should show validation errors (expected due to missing variables) but confirm syntax is correct
4. **Unit Test Execution**: `cd IAC/Terraform/test/terraform && go test -v -timeout 300s --tags=module_test`

#### Bicep Development Flow  
1. **Code Validation**: `cd scripts/orchestrators && export WORKSPACE_PATH=$(pwd)/../.. && ./iac.bicep.lint.sh`
2. **Direct Bicep Test**:
   - `cd IAC/Bicep/bicep/01_storage/01_rg && bicep build main.bicep`
   - Should generate `main.json` ARM template successfully
3. **Template Verification**: Verify generated ARM template exists and contains expected resources

#### Complete Integration Test
1. **Full Lint Suite**: Run MegaLinter to catch all linting issues
2. **Build Validation**: Ensure Terraform init and Bicep compilation work
3. **Authentication Flow**: If Azure credentials available, test `symphony provision` (dry-run mode)

## Key Projects and Structure

### IAC Directory Structure
- `IAC/Terraform/`: Terraform modules and configurations
  - `terraform/01_init/`: Initial Azure resource setup
  - `terraform/02_storage/`: Storage account deployment
  - `terraform/03_config/`: Configuration deployment
  - `test/terraform/`: Go-based Terratest unit tests
- `IAC/Bicep/`: Bicep modules and configurations  
  - `bicep/01_storage/`: Storage resource templates
  - `bicep/02_config/`: Configuration resource templates
  - `bicep/modules/`: Reusable Bicep modules
  - `test/`: ARM TTK and Pester test suites

### Scripts Directory
- `scripts/install/cli/symphony`: Main CLI executable
- `scripts/orchestrators/`: Build, test, and deployment scripts
- `scripts/utilities/`: Shared utility functions

### Configuration Files
- `.mega-linter.yml`: MegaLinter configuration for code quality
- `.github/workflows/`: GitHub Actions workflow templates
- `.azure-pipelines/`: Azure DevOps pipeline templates
- `env/`: Environment-specific configuration files

## Common Issues and Troubleshooting

### Build Issues
- **"terraform: command not found"**: Run `cd scripts/orchestrators && ./setup-terraform.sh`
- **"tflint failed"**: Ensure TFLint is installed: `./setup-tflint.sh`
- **ARM TTK timeout**: This is normal - ARM TTK can take 45-60 seconds. Do not cancel.

### Test Issues  
- **Go test "build constraints exclude all Go files"**: Use correct tags: `--tags=module_test` or `--tags=e2e_test`
- **"FatalError: terraform executable not found"**: Install Terraform before running tests
- **Azure authentication errors**: Tests requiring Azure need `az login` and proper credentials

### Network/Timeout Issues
- **MegaLinter timeouts**: Network-dependent, but linter completes successfully despite timeout warnings
- **Bicep schema timeouts**: Expected when offline, does not affect core functionality

Always run `export WORKSPACE_PATH=$(pwd)` when in the repository root before executing orchestrator scripts.