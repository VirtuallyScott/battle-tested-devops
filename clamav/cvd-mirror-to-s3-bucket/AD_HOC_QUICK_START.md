# ClamAV S3 Sync - Ad-Hoc Quick Start

**Purpose**: Download ClamAV definition files and upload them to S3 bucket in a single operation.

## ⚡ Instant One-Liner (No Configuration Required)

```bash
# Install dependencies, download ClamAV definitions, and upload to S3 in one command
pip install -r requirements.txt && python3 update_databases.py -v --s3-sync --s3-bucket-name your-bucket-name --s3-region us-west-2
```

> **Note**: This uses your default AWS CLI credentials. Ensure `aws configure` is set up or AWS environment variables are configured.

## 🚀 Quick Setup

### 1. Setup Python Environment
```bash
# Create and activate virtual environment
python3 -m venv .venv
source .venv/bin/activate

# Install dependencies
pip install -r requirements.txt
```

### 2. Configure AWS Credentials
```bash
# Option 1: AWS CLI (recommended)
# Note: AWS CLI v1.x will be installed via pip, or install v2 separately
aws configure
# Enter: Access Key ID, Secret Access Key, Region (e.g., us-east-1), Output format (json)

# Option 2: Environment variables
export AWS_ACCESS_KEY_ID=your_access_key_here
export AWS_SECRET_ACCESS_KEY=your_secret_key_here
export AWS_DEFAULT_REGION=us-east-1

# Option 3: Install AWS CLI v2 separately (optional, for latest features)
# macOS: brew install awscli
# Linux: https://docs.aws.amazon.com/cli/latest/userguide/getting-started-install.html
```

### 3. Configure S3 Bucket
```bash
# Set your S3 bucket name
.venv/bin/python config_manager.py set-s3-bucket your-clamav-bucket-name

# Optional: Set S3 region if different from AWS default
.venv/bin/python config_manager.py set-s3-region us-west-2

# Optional: Set S3 prefix for organization
.venv/bin/python config_manager.py set-s3-prefix clamav/databases/

# Enable S3 sync
.venv/bin/python config_manager.py set-s3-sync enabled
```

### 4. Verify Configuration
```bash
# Test S3 connectivity
aws s3 ls s3://your-bucket-name

# Show S3 configuration
.venv/bin/python config_manager.py show-s3
```

## Ad-Hoc Usage (No Config File Setup)

For quick one-time operations, you can specify S3 settings directly via command line without setting up configuration files:

### Update Databases and Sync to S3 (Inline Configuration)
```bash
# Update databases and sync to S3 with inline bucket/region specification
.venv/bin/python update_databases.py -v --s3-sync --s3-bucket-name your-bucket-name --s3-region us-west-2

# Dry run to see what would be uploaded (recommended first)
.venv/bin/python update_databases.py -v --s3-sync --s3-bucket-name your-bucket-name --s3-region us-west-2 --dry-run

# Using environment variables (alternative approach)
S3_BUCKET_NAME=your-bucket-name S3_REGION=us-west-2 .venv/bin/python s3_sync.py --upload --verbose

# Environment variables with dry run
S3_BUCKET_NAME=your-bucket-name S3_REGION=us-west-2 .venv/bin/python s3_sync.py --upload --verbose --dry-run
```

**Note:** When using inline configuration, the CLI arguments override any existing configuration files.

## 🎯 Ad-Hoc Execution Commands

### Single Command: Download + Upload (with inline S3 config)
```bash
# Download ClamAV definitions and upload to S3 in one step (no config file needed)
.venv/bin/python update_databases.py -v --s3-sync --s3-bucket-name wvitc-clamav-definitions --s3-region us-west-2
```

### Single Command: Download + Upload (using config file)
```bash
# Download ClamAV definitions and upload to S3 in one step
.venv/bin/python update_databases.py -v --s3-sync
```

### Step-by-Step Commands
```bash
# 1. Download ClamAV definition files (CVD) and generate diff files (CLD, DAT)
.venv/bin/python update_databases.py -v

# 2. Generate missing freshclam files (CLD and DAT files)
.venv/bin/python generate_missing_files.py -v

# 3. Upload all files to S3
.venv/bin/python s3_sync.py --upload
```

### Emergency/Force Update
```bash
# Force fresh download and upload (ignore timestamps)
.venv/bin/python update_databases.py --force --s3-sync

# Or step-by-step with force
.venv/bin/python update_databases.py --force
.venv/bin/python s3_sync.py --upload --force
```

## 📋 What Gets Downloaded & Uploaded

### ClamAV Definition Files (CVD format)
- `main.cvd` - Main virus definitions
- `daily.cvd` - Daily updates
- `bytecode.cvd` - Bytecode signatures

### FreshClam Diff Files (CLD format)
- `main.cld` - Compressed local database
- `daily.cld` - Compressed daily updates  
- `bytecode.cld` - Compressed bytecode
- `freshclam.dat` - FreshClam metadata
- `mirrors.dat` - Mirror configuration

### Metadata Files
- `.cvdupdate/state.json` - Update state tracking
- Sync logs and timestamps

## ✅ Verification

### Check Local Files
```bash
# List downloaded files
.venv/bin/python update_databases.py -l

# Check system health
.venv/bin/python monitor.py --health
```

### Verify S3 Upload
```bash
# List files in S3 bucket
aws s3 ls s3://your-bucket-name/clamav/databases/ --recursive

# Check sync status
.venv/bin/python monitor.py --s3-status
```

## 🔧 Troubleshooting

### Common Issues
```bash
# Test S3 connection
.venv/bin/python s3_sync.py --test-connection

# Show current configuration
.venv/bin/python config_manager.py show

# Dry run to see what would be synced
.venv/bin/python s3_sync.py --dry-run

# Check logs for errors
tail -f ~/.cvdupdate/logs/cvdupdate.log
```

### Permission Issues
- Ensure your AWS user/role has S3 permissions: `s3:GetObject`, `s3:PutObject`, `s3:ListBucket`
- Verify bucket exists and is accessible: `aws s3 ls s3://your-bucket-name`

---

**Ready to run!** Execute one of these commands:

**Quick (no config needed):**
```bash
python3 update_databases.py -v --s3-sync --s3-bucket-name your-bucket-name --s3-region us-west-2
```

**Using config file:**
```bash
python3 update_databases.py -v --s3-sync
```