#!/bin/bash

# Check if the URL argument is provided
if [ -z "$1" ]; then
    echo "Usage: $0 <URL>"
    exit 1
fi

url=$1

# Create necessary directories if they don't exist
directories=(
    "$url"
    "$url/recon"
    "$url/recon/scans"
    "$url/recon/httprobe"
    "$url/recon/potential_takeovers"
    "$url/recon/wayback"
    "$url/recon/wayback/params"
    "$url/recon/wayback/extensions"
)

for dir in "${directories[@]}"; do
    if [ ! -d "$dir" ]; then
        mkdir -p "$dir" || {
            echo "Error: Failed to create directory '$dir'. Exiting."
            exit 1
        }
    fi
done

# Touch necessary files if they don't exist
files=(
    "$url/recon/httprobe/alive.txt"
    "$url/recon/final.txt"
    "$url/recon/potential_takeovers/potential_takeovers.txt"
)

for file in "${files[@]}"; do
    if [ ! -f "$file" ]; then
        touch "$file" || {
            echo "Error: Failed to create file '$file'. Exiting."
            exit 1
        }
    fi
done

# Harvest subdomains with assetfinder
echo "[+] Harvesting subdomains with assetfinder..."
assetfinder "$url" >> "$url/recon/assets.txt"

# Filter subdomains and probe for alive domains
echo "[+] Probing for alive domains..."
cat "$url/recon/final.txt" | sort -u | httprobe -s -p https:443 | sed 's/https\?:\/\///' | tr -d ':443' >> "$url/recon/httprobe/a.txt"
sort -u "$url/recon/httprobe/a.txt" > "$url/recon/httprobe/alive.txt"
rm "$url/recon/httprobe/a.txt"

# Check for possible subdomain takeover
echo "[+] Checking for possible subdomain takeover..."
subjack -w "$url/recon/final.txt" -t 100 -timeout 30 -ssl -c ~/go/src/github.com/haccer/subjack/fingerprints.json -v 3 -o "$url/recon/potential_takeovers/potential_takeovers.txt"

# Scan for open ports
echo "[+] Scanning for open ports..."
nmap -iL "$url/recon/httprobe/alive.txt" -T4 -oA "$url/recon/scans/scanned.txt"

# Scraping wayback data
echo "[+] Scraping wayback data..."
cat "$url/recon/final.txt" | waybackurls >> "$url/recon/wayback/wayback_output.txt"
sort -u "$url/recon/wayback/wayback_output.txt"

# Pull and compile all possible parameters found in wayback data
echo "[+] Pulling and compiling all possible params found in wayback data..."
cat "$url/recon/wayback/wayback_output.txt" | grep '?*=' | cut -d '=' -f 1 | sort -u >> "$url/recon/wayback/params/wayback_params.txt"
for line in $(cat "$url/recon/wayback/params/wayback_params.txt"); do
    echo "$line'='"
done

# Pull and compile js/php/aspx/jsp/json files from wayback output
echo "[+] Pulling and compiling js/php/aspx/jsp/json files from wayback output..."
for line in $(cat "$url/recon/wayback/wayback_output.txt"); do
    ext="${line##*.}"
    if [[ "$ext" == "js" ]]; then
        echo "$line" >> "$url/recon/wayback/extensions/js1.txt"
        sort -u "$url/recon/wayback/extensions/js1.txt" >> "$url/recon/wayback/extensions/js.txt"
    fi
    if [[ "$ext" == "html" ]]; then
        echo "$line" >> "$url/recon/wayback/extensions/jsp1.txt"
        sort -u "$url/recon/wayback/extensions/jsp1.txt" >> "$url/recon/wayback/extensions/jsp.txt"
    fi
    if [[ "$ext" == "json" ]]; then
        echo "$line" >> "$url/recon/wayback/extensions/json1.txt"
        sort -u "$url/recon/wayback/extensions/json1.txt" >> "$url/recon/wayback/extensions/json.txt"
    fi
    if [[ "$ext" == "php" ]]; then
        echo "$line" >> "$url/recon/wayback/extensions/php1.txt"
        sort -u "$url/recon/wayback/extensions/php1.txt" >> "$url/recon/wayback/extensions/php.txt"
    fi
    if [[ "$ext" == "aspx" ]]; then
        echo "$line" >> "$url/recon/wayback/extensions/aspx1.txt"
        sort -u "$url/recon/wayback/extensions/aspx1.txt" >> "$url/recon/wayback/extensions/aspx.txt"
    fi
done

# Remove temporary files
rm "$url/recon/wayback/extensions/js1.txt" \
   "$url/recon/wayback/extensions/jsp1.txt" \
   "$url/recon/wayback/extensions/json1.txt" \
   "$url/recon/wayback/extensions/php1.txt" \
   "$url/recon/wayback/extensions/aspx1.txt"
