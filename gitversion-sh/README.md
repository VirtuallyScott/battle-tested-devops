# GitVersion Shell Script

A lightweight shell implementation of [GitVersion](https://github.com/GitTools/GitVersion) that automatically generates semantic version numbers from your Git repository history.

## Features

- **Automatic Semantic Versioning**: Calculates version numbers based on Git history and branch structure
- **Multiple Workflow Support**: GitFlow, GitHubFlow, and trunk-based development workflows
- **Commit Message Parsing**: Detects version increments from conventional commit messages
- **Branch-Aware Versioning**: Different versioning strategies for main, develop, feature, release, and hotfix branches
- **Flexible Output**: Support for both human-readable text and structured JSON output
- **Pre-release Versions**: Automatic generation of alpha, beta, and feature-specific pre-release versions
- **Build Metadata**: Includes commit count and SHA information

## Installation

```bash
# Download and make executable
curl -o gitversion.sh https://raw.githubusercontent.com/your-repo/gitversion.sh
chmod +x gitversion.sh

# Optionally, move to PATH
sudo mv gitversion.sh /usr/local/bin/gitversion
```

## Usage

### Basic Usage

```bash
# Calculate version for current branch
./gitversion.sh

# Output: 1.2.3+5+abc1234
```

### Command Line Options

```bash
gitversion [OPTIONS]

OPTIONS:
    -h, --help              Show help message
    -v, --version           Show version information
    -o, --output FORMAT     Output format (json|text) [default: text]
    -c, --config FILE       Path to configuration file
    -b, --branch BRANCH     Target branch [default: current branch]
    -w, --workflow TYPE     Workflow type (gitflow|githubflow|trunk) [default: gitflow]
    --major                 Force major version increment
    --minor                 Force minor version increment
    --patch                 Force patch version increment
    --next-version VERSION  Override next version
```

### Examples

```bash
# Basic version calculation
gitversion

# JSON output for CI/CD integration
gitversion -o json

# Calculate version for specific branch
gitversion -b main

# Force major version increment
gitversion --major

# Use GitHub Flow workflow
gitversion -w githubflow

# Override next version
gitversion --next-version 2.0.0
```

## Workflows

### GitFlow (Default)

Perfect for projects using the GitFlow branching model:

- **main/master**: Stable releases (1.0.0)
- **develop**: Development versions (1.1.0-alpha.5)
- **feature/***: Feature branches (1.1.0-feature-name.3)
- **release/***: Release candidates (1.1.0-beta.2)
- **hotfix/***: Hotfix versions (1.0.1-hotfix.1)

### GitHubFlow

Simplified workflow for GitHub-style development:

- **main/master**: Stable releases
- **feature branches**: Pre-release versions with branch name

### Trunk-based

All branches treated as main branch versions.

## Version Increment Detection

The script automatically detects version increments from commit messages:

### Semantic Version Tags

Add these tags to commit messages to control version increments:

```bash
git commit -m "fix: resolve login issue +semver: patch"
git commit -m "feat: add user profiles +semver: minor"  
git commit -m "feat!: redesign API +semver: major"
```

### Conventional Commits

The script also recognizes conventional commit patterns:

- `feat:` → Minor increment
- `feat!:` → Major increment (breaking change)
- `fix:` → Patch increment
- `BREAKING CHANGE:` → Major increment

## Configuration

### Configuration File

Create a `gitversion.json` configuration file:

```json
{
  "workflow": "gitflow",
  "next-version": "1.0.0",
  "tag-prefix": "v",
  "branches": {
    "main": {
      "increment": "patch",
      "prevent-increment-of-merged-branch-version": true
    },
    "develop": {
      "increment": "minor",
      "pre-release-tag": "alpha"
    },
    "feature": {
      "increment": "minor",
      "pre-release-tag": "{BranchName}"
    },
    "release": {
      "increment": "none",
      "pre-release-tag": "beta"
    },
    "hotfix": {
      "increment": "patch",
      "pre-release-tag": "hotfix"
    }
  }
}
```

### Environment Variables

```bash
export GITVERSION_WORKFLOW=githubflow
export GITVERSION_OUTPUT=json
export DEBUG=true  # Enable debug logging
```

## Output Formats

### Text Output (Default)

```
1.2.3-alpha.5+10+abc1234
```

### JSON Output

```json
{
  "Major": 1,
  "Minor": 2,
  "Patch": 3,
  "PreReleaseTag": "alpha.5",
  "PreReleaseTagWithDash": "-alpha.5",
  "BuildMetaData": "10+abc1234",
  "BuildMetaDataPadded": "+10+abc1234",
  "FullBuildMetaData": "10+abc1234",
  "MajorMinorPatch": "1.2.3",
  "SemVer": "1.2.3-alpha.5+10+abc1234",
  "AssemblySemVer": "1.2.3.0",
  "AssemblySemFileVer": "1.2.3.0",
  "FullSemVer": "1.2.3-alpha.5+10+abc1234",
  "InformationalVersion": "1.2.3-alpha.5+10+abc1234",
  "BranchName": "develop",
  "EscapedBranchName": "develop",
  "Sha": "abc1234567890def",
  "ShortSha": "abc1234",
  "NuGetVersionV2": "1.2.3-alpha.5+10+abc1234",
  "NuGetVersion": "1.2.3-alpha.5+10+abc1234",
  "VersionSourceSha": "abc1234567890def",
  "CommitsSinceVersionSource": 10,
  "CommitDate": "2025-01-15 10:30:45 +0000"
}
```

## CI/CD Integration

### GitHub Actions

```yaml
- name: Calculate Version
  id: version
  run: |
    VERSION=$(./gitversion.sh)
    echo "version=$VERSION" >> $GITHUB_OUTPUT
    
- name: Build and Tag
  run: |
    docker build -t myapp:${{ steps.version.outputs.version }} .
```

### GitLab CI

```yaml
version:
  script:
    - VERSION=$(./gitversion.sh)
    - echo "VERSION=$VERSION" >> build.env
  artifacts:
    reports:
      dotenv: build.env
```

### Jenkins

```groovy
pipeline {
    stages {
        stage('Version') {
            steps {
                script {
                    def version = sh(script: './gitversion.sh', returnStdout: true).trim()
                    env.VERSION = version
                }
            }
        }
    }
}
```

## Branch Strategies

### Feature Branches

```bash
# On feature/user-auth branch
gitversion
# Output: 1.1.0-user-auth.3+15+def5678
```

### Release Branches

```bash
# On release/1.2.0 branch  
gitversion
# Output: 1.2.0-beta.2+8+ghi9012
```

### Hotfix Branches

```bash
# On hotfix/critical-fix branch
gitversion  
# Output: 1.1.1-hotfix.1+2+jkl3456
```

## Troubleshooting

### Debug Mode

Enable debug logging to see how versions are calculated:

```bash
DEBUG=true ./gitversion.sh
```

### Common Issues

1. **No version tags found**: The script starts from 0.0.0 if no semantic version tags exist
2. **Invalid tag format**: Ensure tags follow semantic versioning (v1.2.3 or 1.2.3)
3. **Not a git repository**: Run the script from within a git repository
4. **Parsing errors**: Check that commit messages don't contain invalid characters

### Validation

Test version calculation without making changes:

```bash
# Test different scenarios
gitversion -b main
gitversion -b develop  
gitversion --major
gitversion --next-version 2.0.0
```

## Compatibility

- **Shell**: Bash 4.0+ (uses associative arrays)
- **Git**: 2.0+ (uses modern git commands)
- **OS**: Linux, macOS, Windows (with Git Bash/WSL)

## Contributing

1. Fork the repository
2. Create a feature branch
3. Make your changes
4. Add tests for new functionality
5. Submit a pull request

## License

This project is licensed under the MIT License - see the LICENSE file for details.

## Acknowledgments

- Inspired by the original [GitVersion](https://github.com/GitTools/GitVersion) project
- Follows [Semantic Versioning](https://semver.org/) specifications
- Compatible with [Conventional Commits](https://www.conventionalcommits.org/)