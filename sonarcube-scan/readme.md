# SonarQube Demo – Code Quality & Security Analysis

This repository demonstrates how to use **SonarQube** for static code analysis, code quality checks, and security vulnerability detection.

## 1. Access SonarQube Dashboard

Open the SonarQube endpoint in your browser:

```text
http://<EC2-PUBLIC-IP>:9000
```

### Default Login Credentials

| Field | Value |
|---|---|
| Username | admin |
| Password | admin |

Change the default password on your first login.

## 2. Create a Project

1. Log in to the SonarQube dashboard.
2. Click **Create Project**.
3. Select **Manually**.
4. Enter your project name and project key.
5. Generate a project analysis token.
6. Save the token securely.

## 3. Generate SonarQube Token

Navigate to:

**My Account → Security → Generate Token**

Select an appropriate token type and generate your token.

This token will be used by your CI/CD pipeline to authenticate with SonarQube.

## 4. Configure GitHub Actions

Add the following secrets to your GitHub repository:

Navigate to:

**GitHub Repository → Settings → Secrets and variables → Actions → New repository secret**

| Secret Name | Description |
|---|---|
| `SONAR_HOST_URL` | SonarQube endpoint URL |
| `SONAR_TOKEN` | Generated SonarQube project token |

Example:

```text
SONAR_HOST_URL=http://<EC2-PUBLIC-IP>:9000
SONAR_TOKEN=<your-sonarqube-token>
```

Never hardcode tokens in workflow files.

## 5. View Analysis Results

After executing the CI/CD pipeline:

1. Open the SonarQube dashboard.
2. Navigate to **Projects**.
3. Select your project.
4. Review the analysis results.

You can explore:

- **Bugs:** Potential defects in the code.
- **Vulnerabilities:** Security weaknesses.
- **Code Smells:** Maintainability issues.
- **Security Hotspots:** Code requiring security review.
- **Coverage:** Unit test coverage.
- **Duplications:** Duplicate code blocks.
- **Quality Gate:** Overall project quality status.

## 6. Understanding Quality Gates

SonarQube Quality Gates help determine whether code meets defined quality standards.

A Quality Gate can evaluate:

- New bugs
- New vulnerabilities
- Code coverage
- Code duplication
- Maintainability ratings

A failed Quality Gate indicates that the configured quality conditions have not been satisfied.

## Demo Objective

Understand how SonarQube integrates into a DevSecOps workflow to identify code quality issues and security vulnerabilities before code reaches production.