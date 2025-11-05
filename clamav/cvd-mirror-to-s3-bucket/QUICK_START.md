# 🦠 ClamAV Database Management System - Quick Reference

## 🚀 Getting Started

1. **Quick Start (Interactive Menu)**:
   ```bash
   .venv/bin/python start.py
   ```

2. **First Database Update**:
   ```bash
   .venv/bin/python update_databases.py -v
   ```

3. **Check Status**:
   ```bash
   .venv/bin/python monitor.py
   ```

## 📋 Essential Commands

| Task | Command |
|------|---------|
| Update databases | `.venv/bin/python update_databases.py -v` |
| Check system health | `.venv/bin/python monitor.py --health` |
| Show configuration | `.venv/bin/python config_manager.py show` |
| Start mirror server | `.venv/bin/python serve_mirror.py` |
| Generate cron job | `.venv/bin/python schedule_updates.py --cron` |
| Interactive tutorial | `.venv/bin/python example_usage.py` |
| Unified interface | `.venv/bin/python cvd_manager.py --help` |

## 🔧 Common Configuration Tasks

```bash
# Set custom database directory
.venv/bin/python config_manager.py set-dbdir /var/www/html/clamav

# Set custom DNS server
.venv/bin/python config_manager.py set-nameserver 8.8.8.8

# Add custom database
.venv/bin/python config_manager.py add-database linux.cvd <url>

# Backup configuration
.venv/bin/python config_manager.py backup
```

## 📅 Scheduling (Choose One)

### Option 1: Cron Job
```bash
# Generate cron entry
.venv/bin/python schedule_updates.py --cron

# Then manually add to crontab:
crontab -e
```

### Option 2: Background Daemon
```bash
# Run as background service
.venv/bin/python schedule_updates.py --daemon --interval 4
```

## 🌐 Web Server Setup

1. **Update databases first**:
   ```bash
   .venv/bin/python update_databases.py -v
   ```

2. **Set web directory**:
   ```bash
   .venv/bin/python config_manager.py set-dbdir /var/www/html/clamav
   ```

3. **Update again to populate web directory**:
   ```bash
   .venv/bin/python update_databases.py -v
   ```

4. **Test with local server**:
   ```bash
   .venv/bin/python serve_mirror.py
   ```

## 🔍 Troubleshooting

| Problem | Solution |
|---------|----------|
| No databases found | Run `.venv/bin/python update_databases.py -v` |
| Permission errors | Check directory permissions and ownership |
| Network issues | Verify internet connection and DNS |
| Outdated databases | Check health with `.venv/bin/python monitor.py` |

## 📁 Important Paths

- **Config**: `~/.cvdupdate/config.json`
- **Databases**: `~/.cvdupdate/databases/` (or custom path)
- **Logs**: `~/.cvdupdate/logs/`
- **State**: `~/.cvdupdate/state.json`

## 🆘 Get Help

- **Script help**: Add `--help` to any script
- **Interactive tutorial**: `.venv/bin/python example_usage.py`
- **Health check**: `.venv/bin/python monitor.py --health`
- **Status report**: `.venv/bin/python monitor.py --status`

## 🎯 Next Steps

1. Set up automated updates (cron or daemon)
2. Configure your web server to serve databases
3. Test with FreshClam: `DatabaseMirror http://your-server/clamav`
4. Monitor regularly with the health check

---
*For comprehensive documentation, see README.md*