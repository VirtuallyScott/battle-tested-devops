#!/bin/bash

set -euo pipefail

function ensure_wordlist() {
    if [[ ! -f "./subdomains.txt" ]]; then
        echo "[*] Subdomain wordlist not found. Downloading..."
        curl -sSL -o subdomains.txt https://raw.githubusercontent.com/danielmiessler/SecLists/master/Discovery/DNS/subdomains-top1000.txt
        if [[ $? -ne 0 ]]; then
            echo "[ERROR] Failed to download subdomain wordlist."
            exit 1
        fi
    fi
    WORDLIST="./subdomains.txt"
}

function show_help() {
    cat <<EOF
Usage: $0 [--verbose] <domain> [json|html]

Performs domain recon including:
  - WHOIS on domain and resolved IPs
  - NSLOOKUP on domain and www.domain
  - TLS cert checks on HTTPS
  - Subdomain bruteforce
  - SPF, DMARC, DKIM, DNSSEC
  - MX + SMTP test
EOF
    exit 0
}

function log() {
    echo "[*] $1"
}

# Parse args
VERBOSE=false
if [[ "${1:-}" == "--verbose" ]]; then
    VERBOSE=true
    shift
fi

[[ "${1:-}" =~ ^(-h|--help)$ ]] && show_help
[[ $# -lt 1 ]] && show_help

DOMAIN="$1"
OUTPUT="${2:-html}"
[[ "$OUTPUT" != "html" && "$OUTPUT" != "json" ]] && { echo "[ERROR] Invalid format"; exit 1; }

ensure_wordlist

WHOIS_RAW=$(whois "$DOMAIN" 2>/dev/null || true)
WHOIS_DOMAIN=$(echo "$WHOIS_RAW" | sed 's/"/\"/g')
REG_DATE=$(echo "$WHOIS_RAW" | grep -i "Creation Date\|Registered On" | head -n 1 | cut -d: -f2- | xargs)
EXP_DATE=$(echo "$WHOIS_RAW" | grep -i "Expiry Date\|Expiration Date" | head -n 1 | cut -d: -f2- | xargs)
NS_LIST=$(echo "$WHOIS_RAW" | grep -i "Name Server" | awk '{print $NF}' | sort -u | paste -sd ', ' -)

NSLOOKUP_DOMAIN=$(nslookup "$DOMAIN" 2>/dev/null || echo "NSLOOKUP failed")
NSLOOKUP_WWW=$(nslookup "www.$DOMAIN" 2>/dev/null || echo "NSLOOKUP failed")

IP_ADDRS=($(echo "$NSLOOKUP_DOMAIN" | awk '/^Address: /{print $2}'))
if [[ ${#IP_ADDRS[@]} -eq 0 ]]; then
    echo "[ERROR] Could not resolve any IP addresses for $DOMAIN"
    IP_ADDRS=("N/A")
fi

WHOIS_IP=""
for ip in "${IP_ADDRS[@]}"; do
    ip_info=$(whois "$ip" 2>/dev/null | sed 's/"/\"/g' || echo "WHOIS failed")
    WHOIS_IP+="\n== $ip ==\n$ip_info"
done

PING_RESULT=$(ping -c 2 "$DOMAIN" 2>/dev/null | sed 's/"/\"/g' || echo "Ping failed")

SUBDOMAINS=()
while read -r sub; do
    fqdn="$sub.$DOMAIN"
    if host "$fqdn" &>/dev/null; then
        SUBDOMAINS+=("$fqdn")
    fi
done < "$WORDLIST"

MX_RECORDS=$(dig +short MX "$DOMAIN")
MX_IPS=()
SMTP_RESULTS=()
WHOIS_MX_IPS=()

while read -r priority mxhost; do
    [[ -z "$mxhost" ]] && continue
    ip=$(dig +short "$mxhost" | head -n 1)
    MX_IPS+=("$mxhost ($ip)")
    SMTP_RESULTS+=("$(echo | openssl s_client -connect ${mxhost}:25 -starttls smtp 2>/dev/null || echo "SMTP test failed")")
    WHOIS_MX_IPS+=("$(whois "$ip" 2>/dev/null | sed 's/"/\"/g' || echo "WHOIS failed")")
done <<< "$(echo "$MX_RECORDS" | sort)"

SPF=$(dig +short TXT "$DOMAIN" | grep "v=spf" || echo "No SPF record")
DMARC=$(dig +short TXT "_dmarc.$DOMAIN" || echo "No DMARC record")
DKIM=$(dig +short TXT "default._domainkey.$DOMAIN" || echo "No DKIM record")
DNSSEC=$(dig +dnssec "$DOMAIN" | grep RRSIG || echo "No DNSSEC")

SSL_DOMAIN=$(echo | openssl s_client -servername "$DOMAIN" -connect "$DOMAIN:443" 2>/dev/null | openssl x509 -noout -text || echo "TLS check failed")
SSL_WWW=$(echo | openssl s_client -servername "www.$DOMAIN" -connect "www.$DOMAIN:443" 2>/dev/null | openssl x509 -noout -text || echo "TLS check failed")

OUTPUT_FILE="recon-$DOMAIN.$OUTPUT"
{
echo "<html><head><style>
body{font-family:sans-serif;background:#f4f4f4;padding:20px}
h1{color:#00457c}pre{background:#fff;padding:10px;border:1px solid #ccc}
table{background:#fff;border-collapse:collapse;margin-bottom:20px}
td,th{border:1px solid #ccc;padding:8px}th{background:#00539C;color:#fff}
summary{cursor:pointer;background:#00539C;color:#fff;padding:10px;border-radius:5px}
</style></head><body><h1>Recon Report: $DOMAIN</h1>"

echo "<table><tr><th>Domain</th><th>Registered</th><th>Expires</th><th>DNS Servers</th></tr>"
echo "<tr><td>$DOMAIN</td><td>$REG_DATE</td><td>$EXP_DATE</td><td><ul>"
for ns in $(echo $NS_LIST | tr "," "\n"); do echo "<li>$ns</li>"; done
echo "</ul></td></tr></table>"

echo "<details open><summary>IP Addresses</summary><pre>${IP_ADDRS[*]}</pre></details>"
echo "<details><summary>WHOIS Domain</summary><pre>$WHOIS_DOMAIN</pre></details>"
echo "<details><summary>NSLOOKUP</summary><pre>$NSLOOKUP_DOMAIN</pre></details>"
echo "<details><summary>NSLOOKUP (www)</summary><pre>$NSLOOKUP_WWW</pre></details>"
echo "<details><summary>WHOIS IPs</summary><pre>$WHOIS_IP</pre></details>"
echo "<details><summary>Ping</summary><pre>$PING_RESULT</pre></details>"

echo "<details><summary>Subdomains</summary><ul>"
for s in "${SUBDOMAINS[@]}"; do echo "<li>$s</li>"; done
echo "</ul></details>"

echo "<details><summary>SPF</summary><pre>$SPF</pre></details>"
echo "<details><summary>DMARC</summary><pre>$DMARC</pre></details>"
echo "<details><summary>DKIM</summary><pre>$DKIM</pre></details>"
echo "<details><summary>DNSSEC</summary><pre>$DNSSEC</pre></details>"
echo "<details><summary>TLS/SSL - $DOMAIN</summary><pre>${SSL_DOMAIN:0:1500}...</pre></details>"
echo "<details><summary>TLS/SSL - www.$DOMAIN</summary><pre>${SSL_WWW:0:1500}...</pre></details>"

echo "<details><summary>MX IPs</summary><ul>"
for m in "${MX_IPS[@]}"; do echo "<li>$m</li>"; done
echo "</ul></details>"

echo "<details><summary>SMTP Results</summary><ul>"
for r in "${SMTP_RESULTS[@]}"; do echo "<li><pre>${r:0:300}...</pre></li>"; done
echo "</ul></details>"

echo "<details><summary>WHOIS for MX IPs</summary><ul>"
for w in "${WHOIS_MX_IPS[@]}"; do echo "<li><pre>${w:0:300}...</pre></li>"; done
echo "</ul></details>"

echo "</body></html>"
} > "$OUTPUT_FILE"

echo "[*] Recon complete: $OUTPUT_FILE"
