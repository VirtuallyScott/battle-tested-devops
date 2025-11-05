#!/usr/bin/env bash
# create-security-manifest.sh - Generate security manifests for existing releases
# This script can be run independently to create or update security manifests

set -euo pipefail

# Colors for output
RED='\033[0;31m'
GREEN='\033[0;32m'
YELLOW='\033[1;33m'
BLUE='\033[0;34m'
NC='\033[0m' # No Color

log() {
    echo -e "${BLUE}[INFO]${NC} $1"
}

warn() {
    echo -e "${YELLOW}[WARN]${NC} $1"
}

error() {
    echo -e "${RED}[ERROR]${NC} $1" >&2
}

success() {
    echo -e "${GREEN}[SUCCESS]${NC} $1"
}

print_help() {
    cat << EOF
Usage: $0 [OPTIONS]

Generate security manifests (SHA256SUMS, GPG signatures, verification docs) for the current repository state.

OPTIONS:
    --output-dir DIR    Directory to save manifests (default: current directory)
    --include-binaries  Include binary files in checksums
    --sign             Force GPG signing (fail if not possible)
    --no-sign          Skip GPG signing entirely
    -h, --help         Show this help message

EXAMPLES:
    $0                          # Generate manifests in current directory
    $0 --output-dir ./security  # Save manifests to ./security directory
    $0 --include-binaries       # Include binary files in checksums
    $0 --sign                   # Require GPG signing
    $0 --no-sign               # Skip GPG signing

The script creates:
- SHA256SUMS: Checksums for all important files
- SHA256SUMS.sig: GPG signature (if GPG is configured)
- VERIFY.md: Verification instructions
EOF
}

# Generate file checksums
generate_checksums() {
    local output_dir="$1"
    local include_binaries="$2"
    local checksums_file="${output_dir}/SHA256SUMS"

    log "Generating SHA256 checksums..."

    # Base file patterns (text files, scripts, configs)
    local file_patterns=(
        -name "*.sh"
        -name "*.py"
        -name "*.go"
        -name "*.json"
        -name "*.yml"
        -name "*.yaml"
        -name "*.toml"
        -name "*.xml"
        -name "*.md"
        -name "*.txt"
        -name "*.conf"
        -name "*.cfg"
        -name "*.ini"
        -name "Makefile"
        -name "Dockerfile"
        -name "*.dockerfile"
        -name "Containerfile"
        -name "LICENSE*"
        -name "COPYING*"
        -name "*.license"
    )

    # Add binary patterns if requested
    if [[ "$include_binaries" == true ]]; then
        file_patterns+=(
            -name "*.tar.gz"
            -name "*.zip"
            -name "*.deb"
            -name "*.rpm"
            -name "*.dmg"
            -name "*.exe"
            -name "*.msi"
            -name "*.pkg"
        )
    fi

    # Create find command with OR conditions
    local find_cmd="find . -type f \\("
    for ((i=0; i<${#file_patterns[@]}; i++)); do
        find_cmd+=" ${file_patterns[i]}"
        if [[ $i -lt $((${#file_patterns[@]} - 1)) ]]; then
            find_cmd+=" -o"
        fi
    done
    find_cmd+=" \\) ! -path './.git/*' ! -path './build/*' ! -path './scans/*' ! -path './node_modules/*' ! -path './vendor/*'"

    # Execute find and generate checksums
    eval "$find_cmd" | sort | xargs sha256sum > "$checksums_file"

    local file_count
    file_count=$(wc -l < "$checksums_file")
    success "Generated checksums for $file_count files in $checksums_file"
}

# Create GPG signature
create_gpg_signature() {
    local output_dir="$1"
    local force_sign="$2"
    local no_sign="$3"
    local checksums_file="${output_dir}/SHA256SUMS"
    local signature_file="${output_dir}/SHA256SUMS.sig"

    if [[ "$no_sign" == true ]]; then
        log "Skipping GPG signing as requested"
        return 0
    fi

    if ! command -v gpg >/dev/null 2>&1; then
        if [[ "$force_sign" == true ]]; then
            error "GPG not available but signing was forced"
            exit 1
        else
            warn "GPG not available. Skipping signature creation."
            return 0
        fi
    fi

    local gpg_key_id
    gpg_key_id=$(git config --get user.signingkey 2>/dev/null || echo "")

    if [[ -z "$gpg_key_id" ]]; then
        # Try to find a GPG key automatically
        local available_keys
        available_keys=$(gpg --list-secret-keys --with-colons | grep '^sec:' | cut -d: -f5 | head -1)

        if [[ -n "$available_keys" ]]; then
            gpg_key_id="$available_keys"
            warn "No signing key configured, using available key: $gpg_key_id"
            warn "To set permanently: git config user.signingkey $gpg_key_id"
        else
            if [[ "$force_sign" == true ]]; then
                error "No GPG signing key available but signing was forced"
                exit 1
            else
                warn "No GPG signing key configured or available. Skipping signature creation."
                warn "To enable signing: git config user.signingkey <your-key-id>"
                return 0
            fi
        fi
    fi

    log "Creating GPG signature with key: $gpg_key_id"
    if gpg --detach-sign --armor --local-user "$gpg_key_id" --output "$signature_file" "$checksums_file" 2>/dev/null; then
        success "Created GPG signature: $signature_file"

        # Display key info for verification
        log "GPG key fingerprint:"
        gpg --fingerprint "$gpg_key_id" | grep -A1 "pub"
    else
        if [[ "$force_sign" == true ]]; then
            error "Failed to create GPG signature"
            exit 1
        else
            warn "Failed to create GPG signature. Continuing without signature."
        fi
    fi
}

# Create verification documentation
create_verification_docs() {
    local output_dir="$1"
    local has_signature="$2"
    local verify_file="${output_dir}/VERIFY.md"

    log "Creating verification documentation..."

    cat > "$verify_file" << EOF
# Security Verification Guide

This directory contains security manifests for verifying the integrity and authenticity of files.

## Files

- \`SHA256SUMS\` - SHA256 checksums for all important files
$(if [[ "$has_signature" == true ]]; then echo "- \`SHA256SUMS.sig\` - GPG signature of the checksums file"; fi)
- \`VERIFY.md\` - This verification guide (you are here)

## Quick Verification

### 1. Verify File Integrity

\`\`\`bash
# Verify all files listed in SHA256SUMS
sha256sum -c SHA256SUMS

# Verify specific files
sha256sum path/to/file.sh
grep "path/to/file.sh" SHA256SUMS

# Verify and show only successful matches
sha256sum -c SHA256SUMS 2>/dev/null | grep OK
\`\`\`

$(if [[ "$has_signature" == true ]]; then cat << 'GPGEOF'
### 2. Verify GPG Signature

```bash
# Verify the signature (ensures checksums haven't been tampered with)
gpg --verify SHA256SUMS.sig SHA256SUMS

# If you haven't imported the public key yet:
# Method 1: Import from GitHub
curl -L https://github.com/VirtuallyScott.gpg | gpg --import

# Method 2: Import from keyserver (if key is published)
# gpg --keyserver keyserver.ubuntu.com --recv-keys <KEY_ID>
```

### 3. Verify Key Fingerprint

Always verify the GPG key fingerprint matches expected values:

```bash
gpg --fingerprint
```

**Important**: Verify the key fingerprint through multiple independent channels
(GitHub profile, website, direct communication) before trusting signatures.
GPGEOF
fi)

## Security Best Practices

### For Users

1. **Always verify checksums** before using downloaded files
2. **Check GPG signatures** when available to ensure authenticity
3. **Verify key fingerprints** through multiple independent sources
4. **Use HTTPS** when downloading files
5. **Keep verification files** for audit trails

### For Maintainers

1. **Generate manifests** for every release
2. **Use GPG signing** for cryptographic verification
3. **Publish fingerprints** through multiple channels
4. **Document verification** procedures clearly
5. **Rotate keys** periodically and announce changes

## Automated Verification Script

Save this as \`verify-integrity.sh\`:

\`\`\`bash
#!/bin/bash
# Automated integrity verification script

set -euo pipefail

CHECKSUMS_FILE="\${1:-SHA256SUMS}"
SIGNATURE_FILE="\${2:-SHA256SUMS.sig}"

echo "=== File Integrity Verification ==="

if [[ ! -f "\$CHECKSUMS_FILE" ]]; then
    echo "Error: Checksums file \$CHECKSUMS_FILE not found"
    exit 1
fi

# Verify GPG signature if available
if [[ -f "\$SIGNATURE_FILE" ]]; then
    echo "Verifying GPG signature..."
    if gpg --verify "\$SIGNATURE_FILE" "\$CHECKSUMS_FILE"; then
        echo "✓ GPG signature verified"
    else
        echo "✗ GPG signature verification failed"
        exit 1
    fi
else
    echo "⚠ No GPG signature file found (\$SIGNATURE_FILE)"
fi

# Verify file checksums
echo "Verifying file checksums..."
if sha256sum -c "\$CHECKSUMS_FILE"; then
    echo "✓ All file checksums verified"
else
    echo "✗ Checksum verification failed"
    exit 1
fi

echo "🎉 All verifications passed successfully!"
\`\`\`

Make it executable and run:
\`\`\`bash
chmod +x verify-integrity.sh
./verify-integrity.sh
\`\`\`

## Reporting Security Issues

If you discover integrity issues or security vulnerabilities:

1. **Do not use** files that fail verification
2. **Report immediately** through appropriate channels:
   - GitHub Security Advisories
   - Direct contact with maintainers
   - Security mailing lists

## Generated Information

- **Created**: $(date '+%Y-%m-%d %H:%M:%S %Z')
- **System**: $(uname -s) $(uname -r)
- **Checksums**: SHA256
$(if [[ "$has_signature" == true ]]; then echo "- **GPG Key**: $(git config --get user.signingkey 2>/dev/null || gpg --list-secret-keys --with-colons | grep '^sec:' | cut -d: -f5 | head -1)"; fi)
EOF

    success "Created verification documentation: $verify_file"
}

# Main function
main() {
    local output_dir="."
    local include_binaries=false
    local force_sign=false
    local no_sign=false

    # Parse arguments
    while [[ $# -gt 0 ]]; do
        case $1 in
            --output-dir)
                output_dir="$2"
                shift 2
                ;;
            --include-binaries)
                include_binaries=true
                shift
                ;;
            --sign)
                force_sign=true
                shift
                ;;
            --no-sign)
                no_sign=true
                shift
                ;;
            -h|--help)
                print_help
                exit 0
                ;;
            *)
                error "Unknown option: $1"
                print_help
                exit 1
                ;;
        esac
    done

    # Validate conflicting options
    if [[ "$force_sign" == true && "$no_sign" == true ]]; then
        error "Cannot use both --sign and --no-sign options"
        exit 1
    fi

    # Create output directory if it doesn't exist
    if [[ ! -d "$output_dir" ]]; then
        log "Creating output directory: $output_dir"
        mkdir -p "$output_dir"
    fi

    log "Generating security manifests in: $output_dir"

    # Generate checksums
    generate_checksums "$output_dir" "$include_binaries"

    # Create GPG signature
    create_gpg_signature "$output_dir" "$force_sign" "$no_sign"

    # Check if signature was created
    local has_signature=false
    if [[ -f "${output_dir}/SHA256SUMS.sig" ]]; then
        has_signature=true
    fi

    # Create verification documentation
    create_verification_docs "$output_dir" "$has_signature"

    # Summary
    log "Security manifest generation complete!"
    log "Files created in $output_dir:"
    log "  - SHA256SUMS ($(wc -l < "${output_dir}/SHA256SUMS") files)"
    if [[ "$has_signature" == true ]]; then
        log "  - SHA256SUMS.sig (GPG signature)"
    fi
    log "  - VERIFY.md (verification guide)"

    log ""
    log "Quick verification test:"
    log "  cd $output_dir && sha256sum -c SHA256SUMS"
    if [[ "$has_signature" == true ]]; then
        log "  cd $output_dir && gpg --verify SHA256SUMS.sig SHA256SUMS"
    fi
}

# Run main function with all arguments
main "$@"
