# Opera Profile Tools

These scripts allow you to export and import a "golden" Opera browser profile between macOS machines.

## Files

- `export_opera_profile.sh`: Archives the Opera config directory from the current machine, excluding cache and history
- `import_opera_profile.sh`: Restores the profile on a new machine from the exported archive

## Usage

### Export (on source machine)

```bash
chmod +x export_opera_profile.sh
./export_opera_profile.sh
```

This will generate a `.tar.gz` file on your Desktop under `opera_profile_export/`.

### Import (on target machine)

Copy the `.tar.gz` file to the target machine and run:

```bash
chmod +x import_opera_profile.sh
./import_opera_profile.sh /path/to/opera_profile_TIMESTAMP.tar.gz
```

**Note:** This will back up any existing Opera profile before importing.

## Notes

- Passwords and cookies are not portable due to OS-level encryption
- Cache and browsing history are excluded from the export
- This process works best with identical versions of Opera
