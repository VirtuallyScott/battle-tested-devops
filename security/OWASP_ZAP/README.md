# OWASP ZAP Full Scan Script

This directory contains a shell script to run a full security scan using [OWASP ZAP](https://www.zaproxy.org/) in a Docker container.

## Script: `zap_full_scan.sh`

This script automates running a full scan against a target URL using the official ZAP Docker image. It supports output in either JSON or HTML format.

### Usage

```bash
./zap_full_scan.sh -u <URL> -f <json|html>
```

#### Options

- `-u` &nbsp;&nbsp;**Full URL to scan** (e.g. `https://example.com`)
- `-f` &nbsp;&nbsp;**Output format:** `json` or `html`
- `-h` &nbsp;&nbsp;Show help message

If options are not provided, the script will prompt for them interactively.

### Example

```bash
./zap_full_scan.sh -u https://example.com -f html
```

This will run a full scan on `https://example.com` and save the report as an HTML file in the current directory.

### Output

- The report will be saved in the current directory.
- The filename will include a timestamp and a sanitized version of the target URL, e.g. `04212025_153045_example.com.html`.

### Requirements

- [Docker](https://www.docker.com/) must be installed and running.
- The script will automatically pull the official ZAP Docker image if it is not present.

### Notes

- The script mounts the current working directory into the ZAP container to save the report.
- The scan uses ZAP's `zap-full-scan.py` with default options, including a maximum of 10 minutes per scan and a 60-second timeout per target.

For more information on ZAP and its options, see the [OWASP ZAP documentation](https://www.zaproxy.org/docs/).
