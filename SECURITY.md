# Security Policy

## Supported versions

| Version | Supported |
| ------- | --------- |
| `main`  | Yes       |

## Reporting a vulnerability

If you discover a security issue in this project:

1. **Do not** open a public GitHub issue for exploitable vulnerabilities.
2. Email the maintainers with:
   - A description of the issue
   - Steps to reproduce
   - Impact assessment (if known)
3. Allow reasonable time for a fix before public disclosure.

## Security scanning in this repository

This project uses GitHub-native and complementary DevSecOps controls:

- **CodeQL** — static analysis (`.github/workflows/devsecops-github.yaml`)
- **Dependabot** — dependency update and alert automation (`.github/dependabot.yml`)
- **Dependency Review** — PR dependency change gate
- **Secret scanning** — enable in repository **Settings → Code security**
- **SonarQube, Checkov, OWASP ZAP** — additional pipelines under `.github/workflows/`

## Recommended repository settings

Enable in **Settings → Code security and analysis**:

- [ ] Dependency graph
- [ ] Dependabot alerts
- [ ] Dependabot security updates
- [ ] Secret scanning (public repos: on by default; private: requires GitHub Advanced Security)
- [ ] Push protection for secrets
