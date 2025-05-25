# GitHub Actions Complete Course: From Scratch to Production

## Course Overview
**Duration:** 8-10 hours (can be split into 4-5 sessions)  
**Level:** Beginner to Intermediate  
**Prerequisites:** Basic Git/GitHub knowledge, basic command line familiarity

## Learning Objectives
By the end of this course, students will be able to:
- Understand CI/CD concepts and GitHub Actions architecture
- Create, configure, and troubleshoot GitHub Actions workflows
- Implement automated testing, building, and deployment pipelines
- Use marketplace actions and create custom actions
- Apply security best practices for workflows

---

## Module 1: Introduction to CI/CD and GitHub Actions (45 minutes)

### 1.1 What is CI/CD? (15 minutes)
**Continuous Integration (CI):**
- Automatically merge code changes frequently
- Run automated tests on every change
- Catch integration issues early
- Example: Developer pushes code → Tests run automatically → Feedback provided

**Continuous Deployment (CD):**
- Automatically deploy code to production after CI passes
- Reduces manual deployment errors
- Enables faster release cycles
- Example: Tests pass → Code automatically deployed to staging/production

**Real-world analogy:** Think of CI/CD like a factory assembly line where each step is automated and quality-checked before moving to the next stage.

### 1.2 What is GitHub Actions? (15 minutes)
GitHub Actions is GitHub's built-in CI/CD platform that allows you to:
- Automate workflows directly in your repository
- Respond to GitHub events (push, pull request, issue creation)
- Run jobs on GitHub-hosted or self-hosted runners
- Use pre-built actions from the marketplace

**Key Benefits:**
- Integrated with GitHub (no external tools needed)
- Free tier available (2,000 minutes/month for private repos)
- Extensive marketplace of pre-built actions
- Supports multiple operating systems and languages

### 1.3 Core Concepts (15 minutes)
**Workflow:** A automated process defined in YAML file
**Job:** A set of steps that execute on the same runner
**Step:** Individual task within a job
**Action:** Reusable unit of code that performs a specific task
**Runner:** Virtual machine that executes your workflows
**Event:** GitHub activity that triggers a workflow (push, PR, schedule)

**Workflow Structure Hierarchy:**
```
Workflow
├── Job 1
│   ├── Step 1
│   ├── Step 2
│   └── Step 3
└── Job 2
    ├── Step 1
    └── Step 2
```

---

## Module 2: Your First GitHub Action (60 minutes)

### 2.1 Repository Setup (10 minutes)
1. Create a new GitHub repository or use existing one
2. Navigate to the "Actions" tab
3. Observe the suggested workflows based on your repository content
4. Choose "set up a workflow yourself"

### 2.2 Workflow File Structure (20 minutes)
Create `.github/workflows/hello-world.yml`:

```yaml
name: Hello World Workflow

# When should this workflow run?
on:
  push:
    branches: [ main, develop ]
  pull_request:
    branches: [ main ]

# What jobs should run?
jobs:
  say-hello:
    runs-on: ubuntu-latest
    
    steps:
    - name: Checkout code
      uses: actions/checkout@v4
      
    - name: Say hello
      run: echo "Hello, GitHub Actions!"
      
    - name: Display date
      run: date
      
    - name: List files
      run: ls -la
```

**Explanation of each section:**
- `name`: Human-readable name for the workflow
- `on`: Events that trigger the workflow
- `jobs`: Collection of jobs to run
- `runs-on`: Type of virtual machine to use
- `steps`: Individual tasks within the job
- `uses`: Specifies a pre-built action to use
- `run`: Executes command-line commands

### 2.3 Hands-on Exercise (20 minutes)
**Exercise 1: Create and Run Your First Workflow**
1. Create the hello-world.yml file in `.github/workflows/`
2. Commit and push to trigger the workflow
3. Navigate to Actions tab to view the running workflow
4. Examine the logs and output

**Exercise 2: Modify the Workflow**
Add these steps to your workflow:
```yaml
- name: Show environment variables
  run: env
  
- name: Create a file
  run: echo "This file was created by GitHub Actions" > actions-file.txt
  
- name: Display file content
  run: cat actions-file.txt
```

### 2.4 Understanding the Actions Tab (10 minutes)
- Workflow runs history
- Job details and logs
- Re-running failed jobs
- Workflow status badges
- Workflow dispatch (manual triggers)

---

## Module 3: Working with Events and Triggers (45 minutes)

### 3.1 Event Types (20 minutes)
**Common Events:**
```yaml
on:
  # Code events
  push:
    branches: [ main, develop ]
    paths: [ '**.js', '**.py' ]
  pull_request:
    types: [opened, synchronize, closed]
  
  # Issue events
  issues:
    types: [opened, labeled]
  
  # Scheduled events
  schedule:
    - cron: '0 9 * * 1'  # Every Monday at 9 AM UTC
  
  # Manual trigger
  workflow_dispatch:
    inputs:
      environment:
        description: 'Environment to deploy'
        required: true
        default: 'staging'
        type: choice
        options:
        - staging
        - production
```

### 3.2 Practical Examples (25 minutes)
**Example 1: Different workflows for different branches**
```yaml
name: Branch-specific Workflow

on:
  push:
    branches:
      - main      # Production deployment
      - develop   # Staging deployment
      - 'feature/*' # Feature testing

jobs:
  test:
    runs-on: ubuntu-latest
    steps:
    - uses: actions/checkout@v4
    - name: Run tests
      run: echo "Running tests for ${{ github.ref_name }}"
  
  deploy:
    needs: test
    runs-on: ubuntu-latest
    if: github.ref == 'refs/heads/main'
    steps:
    - name: Deploy to production
      run: echo "Deploying to production"
```

**Example 2: Workflow with manual inputs**
```yaml
name: Manual Deployment

on:
  workflow_dispatch:
    inputs:
      environment:
        description: 'Target environment'
        required: true
        type: choice
        options:
        - development
        - staging
        - production
      version:
        description: 'Version to deploy'
        required: true
        type: string

jobs:
  deploy:
    runs-on: ubuntu-latest
    steps:
    - name: Deploy application
      run: |
        echo "Deploying version ${{ inputs.version }} to ${{ inputs.environment }}"
```

---

## Module 4: Jobs, Steps, and Runners (60 minutes)

### 4.1 Understanding Jobs (20 minutes)
**Job Dependencies:**
```yaml
jobs:
  build:
    runs-on: ubuntu-latest
    steps:
    - name: Build application
      run: echo "Building..."
  
  test:
    needs: build  # Wait for build to complete
    runs-on: ubuntu-latest
    steps:
    - name: Run tests
      run: echo "Testing..."
  
  deploy:
    needs: [build, test]  # Wait for both build and test
    runs-on: ubuntu-latest
    if: success()  # Only run if previous jobs succeeded
    steps:
    - name: Deploy
      run: echo "Deploying..."
```

**Parallel vs Sequential Jobs:**
```yaml
jobs:
  # These jobs run in parallel
  lint:
    runs-on: ubuntu-latest
    steps:
    - name: Lint code
      run: echo "Linting..."
  
  unit-tests:
    runs-on: ubuntu-latest
    steps:
    - name: Unit tests
      run: echo "Unit testing..."
  
  # This job waits for both lint and unit-tests
  integration-tests:
    needs: [lint, unit-tests]
    runs-on: ubuntu-latest
    steps:
    - name: Integration tests
      run: echo "Integration testing..."
```

### 4.2 Runner Types and Matrix Builds (20 minutes)
**Available Runners:**
- `ubuntu-latest`, `ubuntu-22.04`, `ubuntu-20.04`
- `windows-latest`, `windows-2022`, `windows-2019`
- `macos-latest`, `macos-12`, `macos-11`

**Matrix Strategy for Multiple Environments:**
```yaml
jobs:
  test:
    runs-on: ${{ matrix.os }}
    strategy:
      matrix:
        os: [ubuntu-latest, windows-latest, macos-latest]
        node-version: [16, 18, 20]
        include:
          - os: ubuntu-latest
            node-version: 21
        exclude:
          - os: macos-latest
            node-version: 16
    
    steps:
    - uses: actions/checkout@v4
    - name: Setup Node.js
      uses: actions/setup-node@v4
      with:
        node-version: ${{ matrix.node-version }}
    - name: Run tests
      run: npm test
```

### 4.3 Hands-on Exercise (20 minutes)
**Exercise: Create a Multi-Job Workflow**
Create a workflow that:
1. Runs linting and unit tests in parallel
2. Runs integration tests only after both complete successfully
3. Uses matrix strategy to test on multiple Node.js versions
4. Has a conditional deployment job

```yaml
name: Complete CI Pipeline

on:
  push:
    branches: [ main, develop ]
  pull_request:
    branches: [ main ]

jobs:
  lint:
    runs-on: ubuntu-latest
    steps:
    - uses: actions/checkout@v4
    - uses: actions/setup-node@v4
      with:
        node-version: '18'
    - run: npm ci
    - run: npm run lint

  unit-test:
    runs-on: ${{ matrix.os }}
    strategy:
      matrix:
        os: [ubuntu-latest, windows-latest]
        node-version: [16, 18, 20]
    steps:
    - uses: actions/checkout@v4
    - uses: actions/setup-node@v4
      with:
        node-version: ${{ matrix.node-version }}
    - run: npm ci
    - run: npm test

  integration-test:
    needs: [lint, unit-test]
    runs-on: ubuntu-latest
    steps:
    - uses: actions/checkout@v4
    - uses: actions/setup-node@v4
      with:
        node-version: '18'
    - run: npm ci
    - run: npm run test:integration

  deploy:
    needs: integration-test
    runs-on: ubuntu-latest
    if: github.ref == 'refs/heads/main' && success()
    steps:
    - name: Deploy to production
      run: echo "Deploying to production"
```

---

## Module 5: Environment Variables and Secrets (45 minutes)

### 5.1 Environment Variables (15 minutes)
**Built-in Environment Variables:**
```yaml
steps:
- name: Display GitHub context
  run: |
    echo "Repository: $GITHUB_REPOSITORY"
    echo "Actor: $GITHUB_ACTOR"
    echo "SHA: $GITHUB_SHA"
    echo "Ref: $GITHUB_REF"
    echo "Workflow: $GITHUB_WORKFLOW"
    echo "Run ID: $GITHUB_RUN_ID"
```

**Custom Environment Variables:**
```yaml
env:
  NODE_ENV: production
  API_URL: https://api.example.com

jobs:
  build:
    runs-on: ubuntu-latest
    env:
      BUILD_ENV: staging
    steps:
    - name: Use environment variables
      run: |
        echo "Node Environment: $NODE_ENV"
        echo "API URL: $API_URL"
        echo "Build Environment: $BUILD_ENV"
      env:
        STEP_SPECIFIC_VAR: "This is step-specific"
```

### 5.2 GitHub Secrets (20 minutes)
**Setting up Secrets:**
1. Go to Repository Settings → Secrets and variables → Actions
2. Click "New repository secret"
3. Add name and value (e.g., `API_KEY`, `DATABASE_URL`)

**Using Secrets in Workflows:**
```yaml
jobs:
  deploy:
    runs-on: ubuntu-latest
    steps:
    - name: Deploy with secret
      run: |
        echo "Deploying with API key"
        # Secret is available but not printed in logs
        curl -H "Authorization: Bearer ${{ secrets.API_KEY }}" \
             https://api.example.com/deploy
      env:
        DATABASE_URL: ${{ secrets.DATABASE_URL }}
```

**Environment-specific Secrets:**
```yaml
jobs:
  deploy:
    runs-on: ubuntu-latest
    environment: production  # Uses production environment secrets
    steps:
    - name: Deploy to production
      run: echo "Deploying with production secrets"
      env:
        PROD_API_KEY: ${{ secrets.PROD_API_KEY }}
```

### 5.3 Security Best Practices (10 minutes)
**Do:**
- Use secrets for sensitive data (API keys, passwords, tokens)
- Use environment protection rules for production deployments
- Limit secret access with environment-specific secrets
- Use OIDC tokens when possible instead of long-lived secrets

**Don't:**
- Put secrets in code or workflow files
- Echo secrets in logs
- Use secrets in pull requests from forks (they won't have access)

---

## Module 6: Using Actions from the Marketplace (60 minutes)

### 6.1 Finding and Understanding Actions (15 minutes)
**GitHub Marketplace:** https://github.com/marketplace?type=actions

**Popular Action Categories:**
- Code checkout: `actions/checkout@v4`
- Language setup: `actions/setup-node@v4`, `actions/setup-python@v4`
- Cloud deployment: `azure/webapps-deploy@v2`
- Testing: `codecov/codecov-action@v3`
- Notifications: `slack-github-action@v1`

**Reading Action Documentation:**
- Check the action's README for usage examples
- Review the action.yml file for inputs and outputs
- Look at version tags and release notes
- Check community usage and issues

### 6.2 Common Workflow Patterns (30 minutes)

**Node.js Application Workflow:**
```yaml
name: Node.js CI/CD

on:
  push:
    branches: [ main, develop ]
  pull_request:
    branches: [ main ]

jobs:
  test:
    runs-on: ubuntu-latest
    steps:
    - uses: actions/checkout@v4
    
    - name: Setup Node.js
      uses: actions/setup-node@v4
      with:
        node-version: '18'
        cache: 'npm'
    
    - name: Install dependencies
      run: npm ci
    
    - name: Run tests
      run: npm test
    
    - name: Upload coverage to Codecov
      uses: codecov/codecov-action@v3
      with:
        file: ./coverage/lcov.info

  build-and-deploy:
    needs: test
    runs-on: ubuntu-latest
    if: github.ref == 'refs/heads/main'
    steps:
    - uses: actions/checkout@v4
    
    - name: Setup Node.js
      uses: actions/setup-node@v4
      with:
        node-version: '18'
        cache: 'npm'
    
    - name: Install and build
      run: |
        npm ci
        npm run build
    
    - name: Deploy to Netlify
      uses: nwtgck/actions-netlify@v2.0
      with:
        publish-dir: './dist'
        production-branch: main
        github-token: ${{ secrets.GITHUB_TOKEN }}
        deploy-message: "Deploy from GitHub Actions"
      env:
        NETLIFY_AUTH_TOKEN: ${{ secrets.NETLIFY_AUTH_TOKEN }}
        NETLIFY_SITE_ID: ${{ secrets.NETLIFY_SITE_ID }}
```

**Python Application Workflow:**
```yaml
name: Python CI

on: [push, pull_request]

jobs:
  test:
    runs-on: ${{ matrix.os }}
    strategy:
      matrix:
        os: [ubuntu-latest, windows-latest, macos-latest]
        python-version: ['3.8', '3.9', '3.10', '3.11']

    steps:
    - uses: actions/checkout@v4
    
    - name: Set up Python
      uses: actions/setup-python@v4
      with:
        python-version: ${{ matrix.python-version }}
    
    - name: Install dependencies
      run: |
        python -m pip install --upgrade pip
        pip install -r requirements.txt
        pip install pytest pytest-cov
    
    - name: Run tests
      run: pytest --cov=./ --cov-report=xml
    
    - name: Upload coverage
      uses: codecov/codecov-action@v3
```

**Docker Build and Push:**
```yaml
name: Docker Build and Push

on:
  push:
    branches: [ main ]
    tags: [ 'v*' ]

jobs:
  build:
    runs-on: ubuntu-latest
    steps:
    - name: Checkout
      uses: actions/checkout@v4
    
    - name: Set up Docker Buildx
      uses: docker/setup-buildx-action@v3
    
    - name: Login to DockerHub
      uses: docker/login-action@v3
      with:
        username: ${{ secrets.DOCKERHUB_USERNAME }}
        password: ${{ secrets.DOCKERHUB_TOKEN }}
    
    - name: Extract metadata
      id: meta
      uses: docker/metadata-action@v5
      with:
        images: myusername/myapp
        tags: |
          type=ref,event=branch
          type=ref,event=pr
          type=semver,pattern={{version}}
          type=semver,pattern={{major}}.{{minor}}
    
    - name: Build and push
      uses: docker/build-push-action@v5
      with:
        context: .
        platforms: linux/amd64,linux/arm64
        push: true
        tags: ${{ steps.meta.outputs.tags }}
        labels: ${{ steps.meta.outputs.labels }}
```

### 6.3 Exercise: Build a Real Project Workflow (15 minutes)
Choose a project type and create a complete workflow:
1. Code checkout
2. Language/runtime setup
3. Dependency installation
4. Testing with coverage
5. Building (if applicable)
6. Deployment or artifact upload

---

## Module 7: Creating Custom Actions (75 minutes)

### 7.1 Types of Actions (15 minutes)
**JavaScript Actions:**
- Run directly on the runner
- Faster execution (no container overhead)
- Access to Node.js ecosystem
- Best for: API integrations, file processing, GitHub API interactions

**Docker Actions:**
- Run in a container
- Consistent environment
- Support any programming language
- Best for: Complex tools, specific runtime requirements

**Composite Actions:**
- Combine multiple steps into a single action
- Use existing actions and shell commands
- Defined in YAML
- Best for: Reusable workflow patterns

### 7.2 Creating a JavaScript Action (30 minutes)
**File Structure:**
```
my-action/
├── action.yml
├── index.js
├── package.json
└── README.md
```

**action.yml:**
```yaml
name: 'My Custom Action'
description: 'A custom action that greets someone'
inputs:
  who-to-greet:
    description: 'Who to greet'
    required: true
    default: 'World'
outputs:
  time:
    description: 'The time we greeted you'
runs:
  using: 'node20'
  main: 'index.js'
```

**package.json:**
```json
{
  "name": "my-custom-action",
  "version": "1.0.0",
  "description": "My first custom action",
  "main": "index.js",
  "dependencies": {
    "@actions/core": "^1.10.0",
    "@actions/github": "^5.1.1"
  }
}
```

**index.js:**
```javascript
const core = require('@actions/core');
const github = require('@actions/github');

try {
  // Get inputs
  const nameToGreet = core.getInput('who-to-greet');
  console.log(`Hello ${nameToGreet}!`);
  
  // Set outputs
  const time = (new Date()).toTimeString();
  core.setOutput("time", time);
  
  // Get the JSON webhook payload for the event
  const payload = JSON.stringify(github.context.payload, undefined, 2);
  console.log(`The event payload: ${payload}`);
  
} catch (error) {
  core.setFailed(error.message);
}
```

### 7.3 Creating a Composite Action (15 minutes)
**action.yml for Composite Action:**
```yaml
name: 'Node.js Setup and Test'
description: 'Setup Node.js and run tests'
inputs:
  node-version:
    description: 'Node.js version to use'
    required: false
    default: '18'
  test-command:
    description: 'Command to run tests'
    required: false
    default: 'npm test'
outputs:
  test-result:
    description: 'Test execution result'
    value: ${{ steps.test.outputs.result }}

runs:
  using: "composite"
  steps:
    - name: Setup Node.js
      uses: actions/setup-node@v4
      with:
        node-version: ${{ inputs.node-version }}
        cache: 'npm'
    
    - name: Install dependencies
      run: npm ci
      shell: bash
    
    - name: Run tests
      id: test
      run: |
        if ${{ inputs.test-command }}; then
          echo "result=success" >> $GITHUB_OUTPUT
        else
          echo "result=failure" >> $GITHUB_OUTPUT
        fi
      shell: bash
```

### 7.4 Using Custom Actions (15 minutes)
**Using your custom action:**
```yaml
name: Test Custom Action

on: [push]

jobs:
  test:
    runs-on: ubuntu-latest
    steps:
    - uses: actions/checkout@v4
    
    # Use action from same repository
    - name: Use custom action
      uses: ./  # or ./.github/actions/my-action
      with:
        who-to-greet: 'GitHub Actions Student'
    
    # Use composite action
    - name: Setup and test
      uses: ./.github/actions/setup-and-test
      with:
        node-version: '20'
        test-command: 'npm run test:ci'
```

**Publishing to Marketplace:**
1. Create a public repository for your action
2. Add proper documentation
3. Tag your releases (v1, v1.0.0, etc.)
4. Add marketplace metadata to action.yml
5. Publish through GitHub interface

---

## Module 8: Advanced Features and Best Practices (60 minutes)

### 8.1 Caching (15 minutes)
**Basic Caching:**
```yaml
steps:
- uses: actions/checkout@v4

- name: Cache node modules
  uses: actions/cache@v3
  with:
    path: ~/.npm
    key: ${{ runner.os }}-node-${{ hashFiles('**/package-lock.json') }}
    restore-keys: |
      ${{ runner.os }}-node-

- name: Install dependencies
  run: npm ci
```

**Advanced Caching Strategies:**
```yaml
- name: Cache multiple paths
  uses: actions/cache@v3
  with:
    path: |
      ~/.npm
      ~/.cache/cypress
      node_modules
    key: ${{ runner.os }}-deps-${{ hashFiles('**/package-lock.json') }}
    restore-keys: |
      ${{ runner.os }}-deps-
```

### 8.2 Artifacts and Outputs (15 minutes)
**Uploading Artifacts:**
```yaml
- name: Upload test results
  uses: actions/upload-artifact@v3
  with:
    name: test-results
    path: |
      test-results.xml
      coverage/
    retention-days: 30

- name: Upload build artifacts
  uses: actions/upload-artifact@v3
  if: success()
  with:
    name: build-${{ github.sha }}
    path: dist/
```

**Downloading Artifacts:**
```yaml
- name: Download build artifacts
  uses: actions/download-artifact@v3
  with:
    name: build-${{ github.sha }}
    path: ./build
```

**Job Outputs:**
```yaml
jobs:
  build:
    outputs:
      version: ${{ steps.version.outputs.version }}
      build-path: ${{ steps.build.outputs.path }}
    steps:
    - id: version
      run: echo "version=$(cat VERSION)" >> $GITHUB_OUTPUT
    - id: build
      run: echo "path=./dist" >> $GITHUB_OUTPUT

  deploy:
    needs: build
    steps:
    - name: Use build outputs
      run: |
        echo "Version: ${{ needs.build.outputs.version }}"
        echo "Build path: ${{ needs.build.outputs.build-path }}"
```

### 8.3 Conditional Execution and Expressions (15 minutes)
**Job and Step Conditions:**
```yaml
jobs:
  deploy:
    if: github.ref == 'refs/heads/main' && success()
    steps:
    - name: Deploy to production
      if: contains(github.event.head_commit.message, '[deploy]')
      run: echo "Deploying..."
    
    - name: Skip deployment
      if: contains(github.event.head_commit.message, '[skip-deploy]')
      run: echo "Skipping deployment"
```

**Complex Conditions:**
```yaml
- name: Conditional step
  if: |
    github.event_name == 'push' &&
    (startsWith(github.ref, 'refs/tags/') || github.ref == 'refs/heads/main') &&
    !contains(github.event.head_commit.message, '[skip ci]')
  run: echo "Complex condition met"
```

### 8.4 Security Best Practices (15 minutes)
**Secure Workflows:**
```yaml
name: Secure Workflow

on:
  pull_request_target:  # Be careful with this event
  workflow_dispatch:

jobs:
  secure-job:
    runs-on: ubuntu-latest
    permissions:
      contents: read
      issues: write
      pull-requests: write
    steps:
    - name: Checkout PR
      uses: actions/checkout@v4
      with:
        ref: ${{ github.event.pull_request.head.sha }}  # Explicit ref
        token: ${{ secrets.GITHUB_TOKEN }}
    
    - name: Validate input
      run: |
        if [[ "${{ github.event.inputs.environment }}" =~ ^[a-zA-Z0-9_-]+$ ]]; then
          echo "Valid input"
        else
          echo "Invalid input" && exit 1
        fi
```

**OIDC Token Usage:**
```yaml
jobs:
  deploy:
    runs-on: ubuntu-latest
    permissions:
      id-token: write
      contents: read
    steps:
    - name: Configure AWS credentials
      uses: aws-actions/configure-aws-credentials@v4
      with:
        role-to-assume: arn:aws:iam::123456789012:role/GitHubAction-AssumeRoleWithAction
        role-session-name: GitHub_to_AWS_via_FederatedOIDC
        aws-region: us-east-1
```

---

## Module 9: Troubleshooting and Debugging (45 minutes)

### 9.1 Common Issues and Solutions (20 minutes)
**Permission Errors:**
```yaml
# Problem: Permission denied
permissions:
  contents: read
  issues: write
  pull-requests: write
  packages: write

# Problem: Token doesn't have enough permissions
- name: Create release
  env:
    GITHUB_TOKEN: ${{ secrets.PERSONAL_ACCESS_TOKEN }}  # Use PAT instead
```

**Environment Issues:**
```yaml
- name: Debug environment
  run: |
    echo "PWD: $(pwd)"
    echo "PATH: $PATH"
    echo "Node version: $(node --version)"
    echo "NPM version: $(npm --version)"
    ls -la
```

**Timeout Issues:**
```yaml
jobs:
  long-running-job:
    runs-on: ubuntu-latest
    timeout-minutes: 60  # Default is 360 minutes
    steps:
    - name: Long running step
      timeout-minutes: 30
      run: ./long-running-script.sh
```

### 9.2 Debugging Techniques (15 minutes)
**Enable Debug Logging:**
Set repository secrets:
- `ACTIONS_STEP_DEBUG` = `true`
- `ACTIONS_RUNNER_DEBUG` = `true`

**Debug Steps:**
```yaml
- name: Debug context
  run: |
    echo "GitHub context:"
    echo "${{ toJSON(github) }}"
    echo "Job context:"
    echo "${{ toJSON(job) }}"
    echo "Steps context:"
    echo "${{ toJSON(steps) }}"
    echo "Runner context:"
    echo "${{ toJSON(runner) }}"
```

**Tmate Debugging (Interactive Shell):**
```yaml
- name: Setup tmate session
  if: failure()
  uses: mxschmitt/action-tmate@v3
  timeout-minutes: 30
```

### 9.3 Testing Workflows Locally (10 minutes)
**Using Act (Run GitHub Actions locally):**
```bash
# Install act
curl https://raw.githubusercontent.com/nektos/act/master/install.sh | sudo bash

# Run workflow
act                           # Run default event (push)
act pull_request             # Run pull_request event
act -j test                  # Run specific job
act -n                       # Dry run

# With secrets
act --secret-file .secrets   # File with KEY=value pairs
act -s GITHUB_TOKEN=...      # Individual secret
```

**Local Testing Best Practices:**
- Use smaller runner images for faster testing
- Test with different events and inputs
- Validate environment variables and secrets
- Check file permissions and paths

---

## Module 10: Real-World Project (90 minutes)

### 10.1 Project Setup (15 minutes)
Create a complete CI/CD pipeline for a web application with:
- Multiple environments (development, staging, production)
- Automated testing (unit, integration, e2e)
- Security scanning
- Deployment with rollback capability
- Notifications

### 10.2 Complete Workflow Implementation (60 minutes)
```yaml
name: Complete CI/CD Pipeline

on:
  push:
    branches: [ main, develop, 'feature/*' ]
  pull_request:
    branches: [ main, develop ]
  schedule:
    - cron: '0 2 * * 1'  # Weekly security scan

env:
  NODE_VERSION: '18'
  REGISTRY: ghcr.io
  IMAGE_NAME: ${{ github.repository }}

jobs:
  # Security and quality checks
  security-scan:
    runs-on: ubuntu-latest
    steps:
    - uses: actions/checkout@v4
      with:
        fetch-depth: 0
    
    - name: Run Trivy vulnerability scanner
      uses: aquasecurity/trivy-action@master
      with:
        scan-type: 'fs'
        scan-ref: '.'
        format: 'sarif'
        output: 'trivy-results.sarif'
    
    - name: Upload Trivy scan results
      uses: github/codeql-action/upload-sarif@v2
      with:
        sarif_file: 'trivy-results.sarif'

  code-quality:
    runs-on: ubuntu-latest
    steps:
    - uses: actions/checkout@v4
    
    - name: Setup Node.js
      uses: actions/setup-node@v4
      with:
        node-version: ${{ env.NODE_VERSION }}
        cache: 'npm'
    
    - name: Install dependencies
      run: npm ci
    
    - name: Lint code
      run: npm run lint
    
    - name: Check formatting
      run: npm run format:check
    
    - name: Type check
      run: npm run type-check

  # Testing suite
  unit-tests:
    runs-on: ubuntu-latest
    strategy:
      matrix:
        node-version: [16, 18, 20]
    steps:
    - uses: actions/checkout@v4
    
    - name: Setup Node.js ${{ matrix.node-version }}
      uses: actions/setup-node@v4
      with:
        node-version: ${{ matrix.node-version }}
        cache: 'npm'
    
    - name: Install dependencies
      run: npm ci
    
    - name: Run unit tests
      run: npm run test:unit -- --coverage
    
    - name: Upload coverage to Codecov
      uses: codecov/codecov-action@v3
      with:
        file: ./coverage/lcov.info
        flags: unit-tests
        name: unit-tests-node-${{ matrix.node-version }}

  integration-tests:
    needs: [code-quality, unit-tests]
    runs-on: ubuntu-latest
    services:
      postgres:
        image: postgres:13
        env:
          POSTGRES_PASSWORD: postgres
          POSTGRES_DB: testdb
        options: >-
          --health-cmd pg_isready
          --health-interval 10s
          --health-timeout 5s
          --health-retries 5
        ports:
          - 5432:5432
      
      redis:
        image: redis:6
        options: >-
          --health-cmd "redis-cli ping"
          --health-interval 10s
          --health-timeout 5s
          --health-retries 5
        ports:
          - 6379:6379
    
    steps:
    - uses: actions/checkout@v4
    
    - name: Setup Node.js
      uses: actions/setup-node@v4
      with:
        node-version: ${{ env.NODE_VERSION }}
        cache: 'npm'
    
    - name: Install dependencies
      run: npm ci
    
    - name: Run database migrations
      run: npm run db:migrate
      env:
        DATABASE_URL: postgresql://postgres:postgres@localhost:5432/testdb
    
    - name: Run integration tests
      run: npm run test:integration
      env:
        DATABASE_URL: postgresql://postgres:postgres@localhost:5432/testdb
        REDIS_URL: redis://localhost:6379

  e2e-tests:
    needs: integration-tests
    runs-on: ubuntu-latest
    steps:
    - uses: actions/checkout@v4
    
    - name: Setup Node.js
      uses: actions/setup-node@v4
      with:
        node-version: ${{ env.NODE_VERSION }}
        cache: 'npm'
    
    - name: Install dependencies
      run: npm ci
    
    - name: Install Playwright browsers
      run: npx playwright install --with-deps
    
    - name: Build application
      run: npm run build
    
    - name: Start application
      run: |
        npm start &
        npx wait-on http://localhost:3000
      env:
        NODE_ENV: test
    
    - name: Run E2E tests
      run: npx playwright test
    
    - name: Upload test results
      uses: actions/upload-artifact@v3
      if: always()
      with:
        name: playwright-report
        path: playwright-report/
        retention-days: 30

  # Build and containerize
  build:
    needs: [security-scan, e2e-tests]
    runs-on: ubuntu-latest
    outputs:
      image-digest: ${{ steps.build.outputs.digest }}
      image-tag: ${{ steps.meta.outputs.tags }}
    steps:
    - uses: actions/checkout@v4
    
    - name: Setup Node.js
      uses: actions/setup-node@v4
      with:
        node-version: ${{ env.NODE_VERSION }}
        cache: 'npm'
    
    - name: Install dependencies
      run: npm ci
    
    - name: Build application
      run: npm run build
    
    - name: Upload build artifacts
      uses: actions/upload-artifact@v3
      with:
        name: build-files
        path: |
          dist/
          package.json
          package-lock.json
    
    - name: Set up Docker Buildx
      uses: docker/setup-buildx-action@v3
    
    - name: Log in to Container Registry
      uses: docker/login-action@v3
      with:
        registry: ${{ env.REGISTRY }}
        username: ${{ github.actor }}
        password: ${{ secrets.GITHUB_TOKEN }}
    
    - name: Extract metadata
      id: meta
      uses: docker/metadata-action@v5
      with:
        images: ${{ env.REGISTRY }}/${{ env.IMAGE_NAME }}
        tags: |
          type=ref,event=branch
          type=ref,event=pr
          type=sha,prefix={{branch}}-
          type=raw,value=latest,enable={{is_default_branch}}
    
    - name: Build and push Docker image
      id: build
      uses: docker/build-push-action@v5
      with:
        context: .
        platforms: linux/amd64,linux/arm64
        push: true
        tags: ${{ steps.meta.outputs.tags }}
        labels: ${{ steps.meta.outputs.labels }}
        cache-from: type=gha
        cache-to: type=gha,mode=max

  # Deployment jobs
  deploy-staging:
    needs: build
    runs-on: ubuntu-latest
    if: github.ref == 'refs/heads/develop'
    environment:
      name: staging
      url: https://staging.example.com
    steps:
    - name: Deploy to staging
      run: |
        echo "Deploying to staging environment"
        echo "Image: ${{ needs.build.outputs.image-tag }}"
        # Add actual deployment commands here
      env:
        STAGING_API_KEY: ${{ secrets.STAGING_API_KEY }}
        KUBE_CONFIG: ${{ secrets.STAGING_KUBE_CONFIG }}
    
    - name: Run smoke tests
      run: |
        curl -f https://staging.example.com/health || exit 1
        echo "Staging deployment successful"

  deploy-production:
    needs: build
    runs-on: ubuntu-latest
    if: github.ref == 'refs/heads/main'
    environment:
      name: production
      url: https://example.com
    steps:
    - name: Deploy to production
      run: |
        echo "Deploying to production environment"
        echo "Image: ${{ needs.build.outputs.image-tag }}"
        # Add actual deployment commands here
      env:
        PROD_API_KEY: ${{ secrets.PROD_API_KEY }}
        KUBE_CONFIG: ${{ secrets.PROD_KUBE_CONFIG }}
    
    - name: Run smoke tests
      run: |
        curl -f https://example.com/health || exit 1
        echo "Production deployment successful"
    
    - name: Create GitHub release
      if: startsWith(github.ref, 'refs/tags/')
      uses: actions/create-release@v1
      env:
        GITHUB_TOKEN: ${{ secrets.GITHUB_TOKEN }}
      with:
        tag_name: ${{ github.ref_name }}
        release_name: Release ${{ github.ref_name }}
        draft: false
        prerelease: false

  # Notifications
  notify:
    needs: [deploy-staging, deploy-production]
    runs-on: ubuntu-latest
    if: always()
    steps:
    - name: Notify Slack
      uses: 8398a7/action-slack@v3
      with:
        status: ${{ job.status }}
        channel: '#deployments'
        webhook_url: ${{ secrets.SLACK_WEBHOOK }}
        fields: repo,message,commit,author,action,eventName,ref,workflow
      env:
        SLACK_WEBHOOK_URL: ${{ secrets.SLACK_WEBHOOK }}
```

### 10.3 Environment Configuration (15 minutes)
**Repository Setup:**
1. **Environments:** Create staging and production environments in repository settings
2. **Secrets:** Add required secrets for each environment
3. **Branch Protection:** Set up rules for main and develop branches
4. **Required Status Checks:** Configure required checks before merging

**Environment-specific configurations:**
- Staging: Automatic deployment, no approval required
- Production: Manual approval required, restrict to main branch
- Both: Environment-specific secrets and variables

---

## Module 11: Monitoring and Optimization (30 minutes)

### 11.1 Workflow Monitoring (15 minutes)
**GitHub Insights:**
- Actions usage and billing
- Workflow performance metrics
- Runner utilization
- Success/failure rates

**Custom Monitoring:**
```yaml
- name: Send metrics to monitoring system
  run: |
    curl -X POST https://metrics.example.com/workflows \
      -H "Content-Type: application/json" \
      -d '{
        "workflow": "${{ github.workflow }}",
        "status": "${{ job.status }}",
        "duration": "${{ steps.timer.outputs.duration }}",
        "branch": "${{ github.ref_name }}"
      }'
  env:
    METRICS_API_KEY: ${{ secrets.METRICS_API_KEY }}
```

### 11.2 Performance Optimization (15 minutes)
**Optimization Strategies:**
1. **Caching:** Use cache actions for dependencies and build artifacts
2. **Parallelization:** Run independent jobs in parallel
3. **Selective Execution:** Use path filters and conditions
4. **Efficient Docker builds:** Multi-stage builds, layer caching
5. **Runner Selection:** Choose appropriate runner sizes

**Example Optimized Workflow:**
```yaml
name: Optimized Workflow

on:
  push:
    paths-ignore:
      - 'docs/**'
      - '*.md'
  pull_request:
    paths-ignore:
      - 'docs/**'
      - '*.md'

jobs:
  changes:
    runs-on: ubuntu-latest
    outputs:
      frontend: ${{ steps.changes.outputs.frontend }}
      backend: ${{ steps.changes.outputs.backend }}
    steps:
    - uses: actions/checkout@v4
    - uses: dorny/paths-filter@v2
      id: changes
      with:
        filters: |
          frontend:
            - 'frontend/**'
          backend:
            - 'backend/**'

  test-frontend:
    needs: changes
    if: needs.changes.outputs.frontend == 'true'
    runs-on: ubuntu-latest
    steps:
    - uses: actions/checkout@v4
    - name: Test frontend
      run: echo "Testing frontend changes"

  test-backend:
    needs: changes
    if: needs.changes.outputs.backend == 'true'
    runs-on: ubuntu-latest
    steps:
    - uses: actions/checkout@v4
    - name: Test backend
      run: echo "Testing backend changes"
```

---

## Module 12: Assessment and Next Steps (45 minutes)

### 12.1 Practical Assessment (30 minutes)
**Assignment: Create a Complete CI/CD Pipeline**

Students must create a workflow that includes:
1. **Multi-stage pipeline** with proper job dependencies
2. **Matrix testing** across different environments
3. **Conditional deployment** based on branch/tags
4. **Proper secret management** and security practices
5. **Custom action** (composite or JavaScript)
6. **Artifact management** and caching
7. **Notification system** for deployment status

**Evaluation Criteria:**
- Workflow structure and organization
- Proper use of GitHub Actions features
- Security best practices implementation
- Error handling and debugging capabilities
- Documentation and comments

### 12.2 Advanced Topics for Further Learning (15 minutes)

**Advanced GitHub Actions Topics:**
- **Self-hosted runners:** Setting up and managing custom runners
- **Reusable workflows:** Creating workflows that can be called from other repositories
- **GitHub Apps integration:** Building custom GitHub Apps with Actions
- **Advanced security:** OIDC, signed commits, supply chain security
- **Enterprise features:** Organization-level actions, runner groups

**Related Technologies:**
- **Infrastructure as Code:** Terraform, Pulumi with GitHub Actions
- **GitOps:** ArgoCD, Flux integration with GitHub Actions
- **Container orchestration:** Kubernetes deployments via Actions
- **Multi-cloud deployments:** AWS, Azure, GCP integration patterns

**Learning Resources:**
- GitHub Actions documentation: https://docs.github.com/en/actions
- GitHub Skills: Interactive tutorials
- Awesome GitHub Actions: Community curated list
- GitHub Actions Toolkit: Development tools for custom actions

---

## Course Summary and Key Takeaways

### What We've Covered
1. **Foundation:** CI/CD concepts and GitHub Actions architecture
2. **Basics:** Creating and configuring workflows, jobs, and steps
3. **Events:** Understanding triggers and workflow automation
4. **Advanced Features:** Matrix builds, environments, secrets management
5. **Marketplace:** Using and creating custom actions
6. **Best Practices:** Security, optimization, and troubleshooting
7. **Real-world Application:** Complete project implementation

### Key Principles to Remember
- **Start Simple:** Begin with basic workflows and gradually add complexity
- **Security First:** Always use secrets for sensitive data and follow security best practices
- **Test Everything:** Use matrix builds and multiple environments for thorough testing
- **Monitor and Optimize:** Regularly review workflow performance and costs
- **Document Well:** Clear documentation helps team collaboration and maintenance

### Next Steps
1. **Practice:** Implement GitHub Actions in your existing projects
2. **Contribute:** Create and share useful actions with the community
3. **Stay Updated:** Follow GitHub's blog and release notes for new features
4. **Join Communities:** Participate in GitHub discussions and community forums
5. **Explore Advanced Features:** Dive deeper into enterprise and advanced use cases

### Final Project Challenge
Create a comprehensive DevOps pipeline for a real application that demonstrates all the concepts learned in this course. Include proper documentation, security measures, and monitoring. Share your solution with the community and get feedback from peers.

---

**Course Complete!** You now have the knowledge and tools to implement professional-grade CI/CD pipelines using GitHub Actions. Remember, the best way to master these concepts is through hands-on practice and continuous learning.