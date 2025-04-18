# Version Management

Provides consistent semantic versioning across CI/CD platforms using GitVersion.

## Scripts

- `get-version.sh` - Returns current semantic version from GitVersion or git tags
- `bump-version.sh` - Safely increments version numbers without triggering CI/CD

## Usage

### Get Current Version
```bash
./versioning/get-version.sh
```

### Bump Version
```bash
# Bump patch version (default)
./versioning/bump-version.sh

# Bump minor version
./versioning/bump-version.sh minor

# Bump major version 
./versioning/bump-version.sh major
```

The bump script:
- Prevents running in CI environments
- Creates an empty commit with [skip ci] to prevent build loops
- Uses GitVersion's commit message approach for version bumps
- Outputs the old and new versions

## Integration

These scripts can be used in:
- Docker builds (to tag images)
- CI/CD pipelines (for version metadata)
- Release automation
- Changelog generation
