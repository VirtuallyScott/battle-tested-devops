# AI Coding Agent Instructions

This repository contains a **production-ready DevOps toolkit** with battle-tested patterns from regulated industries and enterprise environments. Understanding the architectural principles and workflows is crucial for effective contributions.

## 🏗️ Architecture Overview

### Dual GitVersion Implementation
- **`gitversion-go/`**: High-performance Go implementation (~10x faster than shell)
  - Build with `make build` or `make dev` (fmt + vet + test)
  - Uses Go modules, structured as `cmd/`, `pkg/`, `internal/`
  - Cross-platform builds via `make build-all`
- **`gitversion-sh/`**: Shell implementation with comprehensive testing
  - Extensive test suite in `tests/` directory using `./run_tests.sh`
  - Both support identical GitFlow workflows and JSON/YAML configs

### Security-First Approach
- **`security/OWASP_ZAP/`**: OWASP ZAP scanning with Docker integration
- **`iac_wrapper/`**: IaC scanning using Trivy + Checkov with multiple output formats
- **Release Security**: All releases include SHA256SUMS and optional GPG signatures
- Scripts follow security patterns: input validation, error handling, dependency checks

### DevOps Tool Categories
- **Versioning**: GitVersion implementations + release automation
- **Security**: Static/dynamic analysis, container scanning, hardening
- **IaC**: Terraform/Pulumi modules, compliance scanning
- **Observability**: Logging, metrics, alerting patterns
- **Shell Tools**: Python env management (`uv`), system hardening

## 🔧 Critical Developer Workflows

### GitVersion Workflow (Primary Pattern)
```bash
# Check version from any branch
./gitversion-sh/gitversion.sh
gitversion  # If Go version installed

# GitFlow release process
git checkout develop
git checkout -b release/v1.2.0
# GitVersion automatically detects branch and sets pre-release tags
./versioning/create-release.sh  # Automated release with security manifests
```

### Build & Test Patterns
```bash
# Go projects (gitversion-go)
make dev        # Format + vet + unit tests
make build      # Build binary to build/
make test       # Full test suite including integration

# Shell scripts testing
cd gitversion-sh/tests && ./run_tests.sh  # Comprehensive test suite
```

### Security Scanning Workflow
```bash
# IaC security scanning
./iac_wrapper/iac_scanner.sh -t both -o json    # Trivy + Checkov
./iac_wrapper/iac_scanner.sh -t trivy -o html   # HTML reports

# Web app scanning  
./security/OWASP_ZAP/zap_full_scan.sh -u https://example.com -f json
```

## 📁 Project-Specific Conventions

### Script Patterns
- **Shebang**: Always use `#!/usr/bin/env bash` for portability
- **Error Handling**: `set -euo pipefail` in all shell scripts
- **Colored Output**: Consistent color scheme (RED/GREEN/YELLOW/BLUE/NC)
- **Dependency Checks**: All scripts validate required tools before execution
- **Help/Usage**: Comprehensive `--help` documentation with examples

### Directory Structure Logic
```
<tool>/
├── README.md          # Comprehensive docs with examples
├── <tool>.sh          # Main executable script
├── tests/             # Test suite (for shell tools)
└── tmp/               # Test artifacts and fixtures
```

### Configuration Patterns
- **GitVersion**: Support both JSON (`GitVersion.json`) and YAML (`GitVersion.yml`)
- **GitFlow**: Default workflow with specific branch strategies (main/develop/feature/release/hotfix)
- **Testing**: Isolated test environments with cleanup in `tmp/` directories

### Versioning & Release Strategy
- **Semantic Versioning**: Strict adherence with GitVersion automation
- **Release Branches**: `release/v1.2.3` pattern with beta pre-releases
- **Security Manifests**: Every release includes SHA256SUMS + verification docs
- **Commit Messages**: Conventional commits with `+semver:` tags

## 🎯 AI Agent Guidelines

### When Contributing Code
1. **Follow existing patterns**: Match the established directory structure and naming
2. **Include comprehensive tests**: Shell scripts need test suites in `tests/`
3. **Security first**: Validate inputs, handle errors gracefully, check dependencies
4. **Documentation**: Every script needs detailed README with examples and CI/CD integration

### Understanding Context
- **This is production code**: Used in regulated industries, not academic examples
- **GitFlow expertise required**: Understand branch strategies and version calculation
- **Shell scripting proficiency**: Advanced bash patterns, error handling, portability
- **Security awareness**: Input validation, privilege escalation prevention, audit trails

### Key Files to Reference
- `gitversion.json`: Root GitVersion configuration
- `gitversion-go/Makefile`: Go build patterns and quality checks  
- `gitversion-sh/tests/run_tests.sh`: Shell testing methodology
- `versioning/create-release.sh`: Automated release process with security
- `iac_wrapper/iac_scanner.sh`: Multi-tool security scanning patterns

### Common Tasks
- **Adding new tools**: Follow the `<tool>/README.md + <tool>.sh + tests/` pattern
- **Version bumps**: Use `./versioning/bump-version.sh [major|minor|patch]`
- **Security updates**: Always run `./versioning/create-security-manifest.sh`
- **Testing changes**: Use dry-run modes and comprehensive test suites

### Integration Points
- **CI/CD**: GitVersion JSON output drives automation pipelines
- **Security**: IaC scanning integrates with build processes
- **Docker**: Security tools use containerized scanning (ZAP, Trivy)
- **Cross-platform**: Scripts work on Linux/macOS/Windows (Git Bash/WSL)

Remember: This toolkit represents real-world, battle-tested patterns. Maintain the high standards of security, testing, and documentation that make it production-ready.