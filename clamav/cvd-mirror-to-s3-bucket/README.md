# ClamAV Database Update Scripts with S3 Sync

This project contains Python scripts to manage ClamAV database updates using the cvdupdate library from Cisco Talos, with optional S3 bucket synchronization for cloud distribution.

## 🎯 **Execution Modes**

This system is designed for **flexible execution** to meet different operational needs:

### **1. Automated Scheduling (Production)**
- **Cron Jobs**: Set up automated updates every 4-6 hours
- **Background Daemon**: Run as a persistent service
- **Best for**: Production environments requiring continuous updates

### **2. Ad-Hoc Execution (Operational)**
- **One-time Shore-up**: Quickly sync databases during maintenance windows
- **Emergency Updates**: Manually trigger updates when needed
- **Best for**: Operational tasks and maintenance

### **3. Manual Execution (Development/Testing)**
- **Development**: Test configurations and validate functionality
- **Troubleshooting**: Debug issues or verify database integrity
- **Best for**: Development environments and diagnostics

## 🚀 Quick Start

1. **Run the installer** (recommended):
   ```bash
   python3 setup_installer.py
   ```

2. **Manual setup**:
   ```bash
   python3 -m venv .venv
   source .venv/bin/activate  # On Windows: .venv\Scripts\activate
   pip install -r requirements.txt
   ```

3. **Download databases**:
   ```bash
   .venv/bin/python update_databases.py -v
   ```

## 📁 Project Structure

```
cvdupdate/
├── .venv/                    # Virtual environment
├── README.md                 # This file
├── requirements.txt          # Python dependencies
├── setup.sh                  # Shell setup script
├── setup_installer.py        # Automated installer
├── env_setup.py             # Environment configuration
├── update_databases.py       # Database update script
├── serve_mirror.py          # HTTP mirror server
├── config_manager.py        # Configuration management
├── schedule_updates.py      # Scheduled updates
├── monitor.py               # Health monitoring
├── cvd_manager.py           # Unified management interface
└── example_usage.py         # Interactive examples
```

## 📋 Scripts Overview

### Core Scripts

#### `update_databases.py`
Downloads and updates ClamAV databases with comprehensive logging.

```bash
.venv/bin/python update_databases.py -v    # Update with verbose output
.venv/bin/python update_databases.py -l    # List current databases
.venv/bin/python update_databases.py -c    # Show configuration
```

#### `serve_mirror.py`
Serves databases as an HTTP mirror for testing with FreshClam.

```bash
.venv/bin/python serve_mirror.py           # Start server on port 8000
.venv/bin/python serve_mirror.py -p 9000   # Custom port
.venv/bin/python serve_mirror.py --check   # Check database directory
```

#### `config_manager.py`
Manages cvdupdate configuration settings.

```bash
.venv/bin/python config_manager.py show                           # Show current config
.venv/bin/python config_manager.py set-dbdir /path/to/databases   # Set database directory
.venv/bin/python config_manager.py set-logdir /path/to/logs       # Set log directory
.venv/bin/python config_manager.py set-nameserver 8.8.8.8        # Set DNS server
.venv/bin/python config_manager.py add-database linux.cvd <url>   # Add custom database
.venv/bin/python config_manager.py list                           # List databases
.venv/bin/python config_manager.py backup                         # Backup configuration
```

#### `schedule_updates.py`
Manages scheduled database updates.

```bash
.venv/bin/python schedule_updates.py --cron                # Generate cron entry
.venv/bin/python schedule_updates.py --interval 6          # Schedule every 6 hours
.venv/bin/python schedule_updates.py --daemon              # Run as background daemon
.venv/bin/python schedule_updates.py --once                # Run update once
```

### Management Scripts

#### `cvd_manager.py`
Unified interface for all database operations.

```bash
.venv/bin/python cvd_manager.py update -v              # Update databases
.venv/bin/python cvd_manager.py serve -p 9000          # Start mirror server
.venv/bin/python cvd_manager.py config show            # Show configuration
.venv/bin/python cvd_manager.py schedule --cron        # Schedule updates
```

#### `monitor.py`
Health monitoring and status reporting.

```bash
.venv/bin/python monitor.py                    # Health check + status report
.venv/bin/python monitor.py --health           # Health check only
.venv/bin/python monitor.py --status           # Status report only
```

### Utility Scripts

#### `example_usage.py`
Interactive walkthrough of all features.

```bash
.venv/bin/python example_usage.py
```

#### `setup_installer.py`
Automated setup and installation.

```bash
python3 setup_installer.py                     # Full setup
python3 setup_installer.py --quick             # Skip some checks
python3 setup_installer.py --skip-tests        # Skip functionality tests
```

## ⚙️ Configuration

### Default Locations
- **Configuration**: `~/.cvdupdate/config.json`
- **Database files**: `~/.cvdupdate/databases/`
- **Log files**: `~/.cvdupdate/logs/`
- **State file**: `~/.cvdupdate/state.json`

### Custom Configuration
Use the config manager to customize paths:

```bash
# Set custom database directory (useful for web server integration)
.venv/bin/python config_manager.py set-dbdir /var/www/html/clamav

# Set custom log directory
.venv/bin/python config_manager.py set-logdir /var/log/cvdupdate

# Use custom DNS server
.venv/bin/python config_manager.py set-nameserver 1.1.1.1
```

## 🪣 **S3 Bucket Configuration**

The system can optionally sync ClamAV databases to an AWS S3 bucket for cloud distribution and high availability.

### **Prerequisites**

1. **AWS Account**: Active AWS account with S3 access
2. **S3 Bucket**: Pre-created S3 bucket for storing databases
3. **IAM Permissions**: User/role with appropriate S3 permissions
4. **AWS Credentials**: Configured AWS credentials

### **AWS Credentials Setup**

Choose one of the following methods:

#### **Method 1: AWS CLI Configuration (Recommended)**
```bash
# Install AWS CLI (if not already installed)
pip install awscli

# Configure credentials
aws configure
# Enter: Access Key ID, Secret Access Key, Region, Output format
```

#### **Method 2: Environment Variables**
```bash
export AWS_ACCESS_KEY_ID=your_access_key_here
export AWS_SECRET_ACCESS_KEY=your_secret_key_here
export AWS_DEFAULT_REGION=us-east-1
```

#### **Method 3: IAM Role (EC2/ECS)**
If running on AWS infrastructure, use IAM roles attached to the instance.

### **Required IAM Permissions**

Your AWS user/role needs these S3 permissions:

```json
{
    "Version": "2012-10-17",
    "Statement": [
        {
            "Effect": "Allow",
            "Action": [
                "s3:GetObject",
                "s3:PutObject",
                "s3:DeleteObject",
                "s3:ListBucket"
            ],
            "Resource": [
                "arn:aws:s3:::your-clamav-bucket",
                "arn:aws:s3:::your-clamav-bucket/*"
            ]
        }
    ]
}
```

### **S3 Configuration Commands**

Use the config manager to set up S3 sync:

```bash
# Configure S3 bucket
.venv/bin/python config_manager.py set-s3-bucket your-clamav-bucket-name

# Set S3 region (optional, defaults to us-east-1)
.venv/bin/python config_manager.py set-s3-region us-west-2

# Enable/disable S3 sync
.venv/bin/python config_manager.py set-s3-sync enabled

# Set S3 prefix (optional, for organization)
.venv/bin/python config_manager.py set-s3-prefix clamav/databases/

# Show S3 configuration
.venv/bin/python config_manager.py show-s3
```

### **S3 Sync Usage**

#### **Manual S3 Sync (Ad-Hoc)**
```bash
# Sync databases to S3 immediately
.venv/bin/python s3_sync.py --upload

# Download from S3 to local (shore-up scenario)
.venv/bin/python s3_sync.py --download

# Dry run (show what would be synced)
.venv/bin/python s3_sync.py --dry-run

# Force full sync (ignore timestamps)
.venv/bin/python s3_sync.py --force
```

#### **Automated S3 Sync**
```bash
# Update databases and sync to S3 in one command
.venv/bin/python update_databases.py -v --s3-sync

# Include S3 sync in scheduled updates
.venv/bin/python schedule_updates.py --cron --s3-sync
```

### **S3 Bucket Structure**

The system organizes files in S3 as follows:

```
your-bucket/
├── clamav/databases/          # Optional prefix
│   ├── main.cvd
│   ├── daily.cvd
│   ├── bytecode.cvd
│   ├── main.cld
│   ├── daily.cld
│   ├── bytecode.cld
│   ├── freshclam.dat
│   ├── mirrors.dat
│   └── .cvdupdate/
│       ├── state.json
│       └── logs/
└── metadata/
    ├── sync_log.json
    └── last_sync.txt
```

### **S3 Best Practices**

1. **Bucket Versioning**: Enable versioning for database integrity
2. **Lifecycle Policies**: Auto-delete old versions after 30 days
3. **Access Logging**: Enable S3 access logging for audit trails
4. **Encryption**: Use S3 server-side encryption (SSE-S3 or SSE-KMS)
5. **Monitoring**: Set up CloudWatch alerts for sync failures

### **S3 Troubleshooting**

```bash
# Test S3 connectivity
.venv/bin/python s3_sync.py --test-connection

# Verify S3 configuration
.venv/bin/python config_manager.py show-s3

# Check S3 sync logs
.venv/bin/python monitor.py --s3-status

# Manual credential test
aws s3 ls s3://your-bucket-name --region your-region
```

## 🕒 **Flexible Update Scheduling**

The system supports multiple execution patterns to meet different operational needs:

### **Production Automation**

#### Cron Setup (Recommended for Production)
1. Generate cron entry:
   ```bash
   .venv/bin/python schedule_updates.py --cron
   ```

2. Install manually:
   ```bash
   crontab -e
   # Add the generated line, for example:
   30 */4 * * * /path/to/.venv/bin/python /path/to/update_databases.py > /dev/null 2>&1
   ```

3. Include S3 sync in automated updates:
   ```bash
   # Generate cron with S3 sync
   .venv/bin/python schedule_updates.py --cron --s3-sync
   
   # Cron entry will include S3 upload after database update
   30 */4 * * * /path/to/.venv/bin/python /path/to/update_databases.py --s3-sync > /dev/null 2>&1
   ```

#### Background Daemon
Run as a persistent background service:
```bash
# Basic daemon mode
.venv/bin/python schedule_updates.py --daemon --interval 4

# Daemon with S3 sync
.venv/bin/python schedule_updates.py --daemon --interval 6 --s3-sync
```

### **Operational/Ad-Hoc Execution**

#### One-Time Shore-Up Operations
Perfect for maintenance windows or catch-up scenarios:

```bash
# Quick database update and S3 sync
.venv/bin/python update_databases.py -v --s3-sync

# Emergency update (force fresh download)
.venv/bin/python update_databases.py --force --s3-sync

# Shore-up from S3 (download latest from cloud)
.venv/bin/python s3_sync.py --download --force
```

#### Manual Execution Examples

```bash
# Manual update with full logging
.venv/bin/python update_databases.py -v

# Test run without S3 sync
.venv/bin/python update_databases.py --dry-run

# Sync existing databases to S3
.venv/bin/python s3_sync.py --upload

# Check what needs syncing
.venv/bin/python s3_sync.py --dry-run
```

### **Execution Pattern Recommendations**

| **Use Case** | **Execution Method** | **Frequency** | **S3 Sync** |
|--------------|---------------------|---------------|-------------|
| **Production Mirror** | Cron Job | Every 4-6 hours | Yes |
| **Development/Testing** | Manual | As needed | Optional |
| **Emergency Updates** | Ad-hoc | Immediate | Yes |
| **Maintenance Windows** | One-time Shore-up | During maintenance | Yes |
| **Initial Setup** | Manual | Once | Yes |
| **Disaster Recovery** | S3 Download | As needed | Download only |

## 🌐 Mirror Server Usage

1. **Start the server**:
   ```bash
   .venv/bin/python serve_mirror.py
   ```

2. **Configure FreshClam** (`/etc/freshclam.conf` or similar):
   ```
   # Comment out the default mirror
   # DatabaseMirror database.clamav.net
   
   # Add your local mirror
   DatabaseMirror http://localhost:8000
   ```

3. **Test with FreshClam**:
   ```bash
   freshclam -v
   ```

## 🔍 Monitoring and Health Checks

### Health Monitoring
```bash
.venv/bin/python monitor.py --health    # Quick health check
.venv/bin/python monitor.py --status    # Detailed status report
.venv/bin/python monitor.py             # Both health check and status
```

### Status Information
The monitor checks:
- Configuration accessibility
- Database directory existence
- File presence and age
- Update history and timing
- Overall system health

## 🛠️ Advanced Usage

### Web Server Integration
For production use, configure your web server to serve the database directory:

**Apache example**:
```apache
Alias /clamav /home/user/.cvdupdate/databases
<Directory "/home/user/.cvdupdate/databases">
    Options Indexes
    AllowOverride None
    Require all granted
</Directory>
```

**Nginx example**:
```nginx
location /clamav {
    alias /home/user/.cvdupdate/databases;
    autoindex on;
}
```

### Proxy Configuration
If using a proxy:
```bash
# Set proxy environment variables
export http_proxy=http://proxy:8080
export https_proxy=http://proxy:8080

# Set custom nameserver if needed
.venv/bin/python config_manager.py set-nameserver proxy_ip

# Run update
.venv/bin/python update_databases.py -v
```

### Custom Databases
Add additional databases:
```bash
.venv/bin/python config_manager.py add-database linux.cvd https://database.clamav.net/linux.cvd
```

## 🔧 Troubleshooting

### Common Issues

1. **"cvd command not found"**
   - The scripts automatically handle this by using the virtual environment
   - Make sure you're using the virtual environment Python: `.venv/bin/python`

2. **Permission errors**
   - Ensure the database directory is writable
   - Check that scripts are executable: `chmod +x *.py`

3. **Network issues**
   - Check internet connection
   - Verify DNS resolution
   - Configure proxy if needed

4. **Database not updating**
   - Check the monitor: `.venv/bin/python monitor.py --health`
   - Review logs in `~/.cvdupdate/logs/`
   - Ensure sufficient disk space

### Getting Help
- Use `--help` with any script for detailed options
- Check the cvdupdate documentation: https://github.com/Cisco-Talos/cvdupdate
- Run the example walkthrough: `.venv/bin/python example_usage.py`

## 📄 Requirements

- **Python**: 3.6 or newer
- **Internet**: Connection with DNS enabled
- **Disk Space**: Several hundred MB for database files
- **Packages**: cvdupdate and dependencies (automatically installed)

## 🔒 Security Notes

- Database files are downloaded over HTTPS
- Verify database signatures as per ClamAV documentation
- Keep cvdupdate package updated for security patches
- Monitor logs for any unusual activity

## 📝 License

This project follows the same Apache 2.0 license as cvdupdate.
The cvdupdate library is Copyright (C) 2021-2025 Cisco Systems, Inc.