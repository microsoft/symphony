# Orchestrates workflow

Creating pipelines for Infrastructure as code seems easy to build task, but in a mature system, things can get complicated as it needs to handle many changing dynamics parts. A mature workflow for IAC not only automates the deployment of the IAC resources but also incorporates engineering fundamentals, resources validation, dependency management, test execution, security scanning, and more.

## Workflow steps

To ensure best practices in IAC code repos, pipeline workflows need to handle a set of validations on any code change. Note that the details of stages execution may vary based on features available on the orchestrator's IAC tool.

![Workflow steps](images/workflow.png)

### Validate

This stage ensures code readiness. It runs validations and linting tools, scans code for possible cred leaks, and executes any unit tests. Stage steps are executed in the following sequential order.

```mermaid
flowchart LR
    A(Prep Env) --> B(Run Custom Scanners) --> C(Run IAC lint cmd)
    C -->D(Run IAC validate cmd) --> E(Run IAC unit test)
    E -->F(Finalize/Publish reports)

```

### Preview

This stage plans the execution of the IAC code and estimates the scope of the changes. It initializes the IAC tool selected, runs plan/what-if commands to detect the changing scope, and publishes the planning results as an artifact.

```mermaid
flowchart LR
    A(Init IAC tool) --> B(Run IAC cmds to preview changes) --> C(Store preview cmd changes/output)
    C -->D(Check for resources destroy operations)
    D -->E(Finalize/Publish reports)
```

### Deploy

This stage deploys the IAC code to apply the changes from the planning stage. It initializes the IAC tool selected, runs deploy commands to update the resources, and ensures successful resource updates.

```mermaid
flowchart LR
    A(Init IAC tool) --> B(Run IAC Deploy cmds) -->E(Finalize/Publish reports)

```

### Test

This stage executes the integration or end-to-end tests against the recent deployed/updated resources to ensure the configurations/changes are reflected and resources are working as expected. It then publishes the results of the tests and drops them as artifacts for future references.

```mermaid
flowchart LR
    A(Init test framework) --> B(Execute e2e tests) -->E(Finalize/Publish reports)
```

### Report

This stage generates the needed scripts to repro the deployments, publish the created reports, and backup state files if required.

```mermaid
flowchart LR
    A(Generate deplyment scripts) --> B(Publish created scripts) --> E(Backup deployment state)
```
