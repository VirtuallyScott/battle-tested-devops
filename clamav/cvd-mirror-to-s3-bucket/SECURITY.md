# Security Configuration for ClamAV CVD Mirror

## Configuration File Security

This project implements comprehensive security measures to prevent sensitive configuration data from being committed to version control.

### Protected Files

The following files are automatically excluded from git commits via `.gitignore`:

#### Configuration Files
- `config.json` - CVD update configuration
- `s3_config.json` - AWS S3 bucket configuration
- `freshclam.conf` - Temporary FreshClam configuration
- `*.cfg` - General configuration files

#### AWS Credentials
- `.aws/` directory - AWS CLI credentials
- `credentials` - AWS credential files
- `aws_credentials` - Alternative credential files
- `aws_config` - AWS configuration files

#### Database Files
- `*.cvd` - ClamAV virus definition files
- `*.cld` - Compressed local database files  
- `*.cdiff` - Incremental update files
- `*.dat` - Database metadata files
- `*.sign` - Signature files

#### Working Data
- `.cvdupdate/` - CVD update working directory
- `databases/` - Local database storage
- `state.json` - Update state tracking
- `*.log` - Log files

### Configuration Storage

All persistent configuration is stored in the user's home directory:
- `~/.cvdupdate/config.json` - Main CVD update config
- `~/.cvdupdate/s3_config.json` - S3 configuration

This ensures configuration never exists in the repository directory.

### AWS Credentials

The system uses standard AWS credential chain:
1. Environment variables (`AWS_ACCESS_KEY_ID`, `AWS_SECRET_ACCESS_KEY`)
2. AWS CLI configuration (`~/.aws/credentials`)
3. IAM instance profiles (when running on EC2)
4. Container credentials (when running in containers)

**Never store AWS credentials in the repository or project files.**

### Runtime Configuration Override

For ad-hoc usage, S3 configuration can be provided via:
- Command-line arguments: `--s3-bucket-name`, `--s3-region`
- Environment variables: `S3_BUCKET_NAME`, `S3_REGION`

These override any configuration files without creating persistent local config.

### Verification

To verify security configuration:
```bash
# Check git ignore status
git status --ignored

# Verify no sensitive files are tracked
git ls-files | grep -E "\.(json|conf|cfg|credentials)$"

# Check for AWS credentials in environment
env | grep AWS_
```

### Emergency Response

If sensitive data is accidentally committed:
1. **DO NOT** just delete the file - git history preserves it
2. Use `git filter-branch` or BFG Repo-Cleaner to remove from history
3. Rotate any exposed credentials immediately
4. Review access logs for unauthorized usage

### Best Practices

- Always test with `--dry-run` before real operations
- Use separate AWS IAM users with minimal S3 permissions
- Regularly audit AWS CloudTrail logs for S3 access
- Monitor S3 bucket access patterns for anomalies
