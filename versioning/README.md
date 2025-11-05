# Semantic Version Management

Provides consistent semantic versioning across CI/CD platforms using GitVersion with safe automation.

## Features

- Automatic version detection from git history and tags
- Safe version bumping without triggering CI/CD loops
- Support for semantic versioning (SemVer 2.0)
- Integration with Docker, CI/CD pipelines, and release automation
- Configurable version bump strategies via gitversion.yml

## Scripts

| Script | Description |
|--------|-------------|
| `get-version.sh` | Returns current semantic version from GitVersion or falls back to git tags |
| `bump-version.sh` | Safely increments version numbers without triggering CI/CD |

## Usage

### Get Current Version
```bash
# Basic usage
./versioning/get-version.sh

# Example output: 1.2.3+sha.abc1234
```

### Bump Version
```bash
# Bump patch version (default)
./versioning/bump-version.sh

# Bump minor version
./versioning/bump-version.sh minor

# Bump major version
./versioning/bump-version.sh major

# Example output:
# Version bumped from 1.2.3 to 1.2.4
```

### Advanced Usage
```bash
# Get full version info (requires jq)
gitversion | jq

# Get specific version component
gitversion | jq -r '.Major'  # 1
gitversion | jq -r '.Minor'  # 2
gitversion | jq -r '.Patch'  # 3
```

## Integration Examples

### Docker Build
```bash
VERSION=$(./versioning/get-version.sh)
docker build -t myapp:$VERSION .
```

### CI/CD Pipeline
```yaml
steps:
  - name: Get Version
    run: |
      VERSION=$(./versioning/get-version.sh)
      echo "VERSION=$VERSION" >> $GITHUB_ENV
```

### Release Automation
```bash
# Create release tag after version bump
VERSION=$(./versioning/get-version.sh)
git tag v$VERSION
git push origin v$VERSION
```

## Configuration

The `gitversion.yml` file controls versioning behavior. Key settings:

- `assembly-versioning-scheme`: How assembly versions are generated
- `major-version-bump-message`: Commit messages that trigger major bumps
- `branches`: Versioning rules per branch type (main, develop, feature etc)

See [GitVersion docs](https://gitversion.net/docs) for full configuration options.

## Best Practices

1. Bump versions locally before pushing changes
2. Use `[skip ci]` in version bump commits
3. Tag releases after successful builds
4. Document version changes in changelogs
5. Keep gitversion.yml in sync across environments
