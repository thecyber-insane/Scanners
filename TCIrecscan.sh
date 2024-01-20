#!/bin/bash

# Color Code
GREEN='\033[0;32m'
REDIN='\033[0;31m'
YELLO='\033[0;33m'
NC='\033[0m' # No color

# Function to print the banner
print_banner() {
  echo -e "${GREEN}#########################################################${NC}"
  echo -e "${GREEN}#                                                       #${NC}"
  echo -e "${REDIN}#                  TCIrecscan.sh                        #${NC}"
  echo -e "${GREEN}#                                                       #${NC}"
  echo -e "${YELLO}#           Developed by thecyberinsane                 #${NC}"
  echo -e "${GREEN}#            https://github.com/Nithin-X                #${NC}"
  echo -e "${GREEN}#                                                       #${NC}"
  echo -e "${GREEN}#########################################################${NC}"
}

# Output directory
output_dir="TCIrescan_output"

# Check if output directory exists
if [ -d "$output_dir" ]; then
  echo "Error: $output_dir already exists."
  continue
fi

# Create output directory
mkdir "$output_dir"
echo "Output directory created: $output_dir"
echo

# Change to output directory
cd "$output_dir"

# Call the print_banner function
print_banner

# Check if argument is provided
if [ -z "$1" ]; then
  echo "Syntax Error: ./TCIrecscan.sh <Domain>"
  exit 1
fi

# Define target domain
target=$1
echo "Scanning the Domain: $target"
echo

# Output files
open_ports_file="open_ports.txt"
vulnerabilities_file="vulnerabilities.txt"
directories_file="directories.txt"
nikto_report="nikto_report.txt"
whatweb_report="whatweb_report.txt"

# Run Nmap scan to find open ports
echo "Scanning for open ports..."
nmap -p- -T4 "$target" | grep ^[0-9] | cut -d'/' -f1 | tr '\n' ',' | sed 's/,$//' > "$open_ports_file"
echo "Open ports saved to $open_ports_file"

# Run Nmap scan using the gathered open ports
echo "Scanning with Nmap using the gathered open ports..."
nmap -p "$(cat "$open_ports_file")" -A "$target" | tee "$vulnerabilities_file"

# Run Gobuster to find directories
echo "Scanning for directories with Gobuster..."
gobuster dir -u "http://$target" -w /usr/share/wordlists/dirb/common.txt -e -x html,php,zip,js > "$directories_file"

# Run Nikto to find vulnerabilities
echo "Scanning for vulnerabilities with Nikto..."
nikto -h "$target" -output "$nikto_report"
grep "+ " "$nikto_report" | sed 's/+ //g' >> "$vulnerabilities_file"
echo "Nikto vulnerabilities saved to $vulnerabilities_file"

# Run WhatWeb to find vulnerabilities
echo "Scanning for vulnerabilities with WhatWeb..."
whatweb "$target" > "$whatweb_report"
grep "\[+\]" "$whatweb_report" | awk -F ': ' '{print $2}' >> "$vulnerabilities_file"
echo "WhatWeb vulnerabilities saved to $vulnerabilities_file"

echo -e "${GREEN}#########################################################${NC}"
echo -e "${GREEN}#                                                        #${NC}"
echo -e "${GREEN}#                  TCIrecscan.sh                         #${NC}"
echo -e "${REDIN}#                 SCAN COMPLETED!!!                      #${NC}"
echo -e "${GREEN}#                                                        #${NC}"
echo -e "${GREEN}#########################################################${NC}"
