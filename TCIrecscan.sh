#!/bin/bash

# Check if running with root permissions
if [[ $EUID -ne 0 ]]; then
   echo "This script must be run as root." 
   exit 1
fi

# Default output directory
default_output_dir="TCIrescan_output"
output_dir=""

# Function to print the banner
print_banner() {
  echo -e "${GREEN}#########################################################${NC}"
  echo -e "${GREEN}#                                                       #${NC}"
  echo -e "${REDIN}#                  TCIrecscan.sh                        #${NC}"
  echo -e "${GREEN}#                                                       #${NC}"
  echo -e "${YELLO}#           Developed by thecyber-insane                #${NC}"
  echo -e "${GREEN}#            https://github.com/thecyber-insane         #${NC}"
  echo -e "${GREEN}#                                                       #${NC}"
  echo -e "${GREEN}#########################################################${NC}"
}

# Function to display help
Help() {
  echo "Usage: $0 [-h] [-o <output_directory>] <Domain>"
  echo "Options:"
  echo "  -h            Display this help message"
  echo "  -o <dir>      Specify output directory (default: $default_output_dir)"
  echo
}

# Function to install SecLists if not present
install_seclists() {
  echo "Installing SecLists..."
  cd /usr/share || exit 1
  git clone https://github.com/danielmiessler/SecLists.git
  echo "SecLists installed."
}

# Parse command-line options
while getopts ":ho:" option; do
  case $option in
    h) # Display Help
      Help
      exit;;
    o) # Specify output directory
      output_dir="$OPTARG"
      ;;
    :) # Missing argument for option
      echo "Option -$OPTARG requires an argument."
      Help
      exit 1
      ;;
    \?) # Invalid option
      echo "Invalid option: -$OPTARG"
      Help
      exit 1
      ;;
  esac
done

# Shift to process remaining arguments after options
shift $((OPTIND - 1))

# Check if argument is provided (Domain)
if [ -z "$1" ]; then
  echo "Syntax Error: $0 [-h] [-o <output_directory>] <Domain>"
  exit 1
fi

# Define target domain
target="$1"
echo "Scanning the Domain: $target"
echo

# Determine final output directory
if [ -z "$output_dir" ]; then
  output_dir="$default_output_dir"
fi

# Check if specified output directory exists, if not, create it
if [ ! -d "$output_dir" ]; then
  mkdir -p "$output_dir"
  echo "Output directory created: $output_dir"
  echo
else
  echo "$output_dir already exists! Directory creation skipped!!!"
fi

# Change to output directory
cd "$output_dir" || exit 1

# Call the print_banner function
print_banner

# Check if SecLists directory exists in /usr/share
seclists_dir="/usr/share/SecLists"
if [ ! -d "$seclists_dir" ]; then
  install_seclists
else
  echo "SecLists already installed in $seclists_dir."
fi

# Run Nmap scan to find open ports
echo "Scanning for open ports..."
nmap -p- -T4 "$target" | grep ^[0-9] | cut -d'/' -f1 | tr '\n' ',' | sed 's/,$//' > "open_ports.txt"
echo "Open ports saved to open_ports.txt"

# Run Nmap scan using the gathered open ports
echo "Scanning with Nmap using the gathered open ports..."
nmap -p "$(cat "open_ports.txt")" -A "$target" | tee "nmap_full_scan.txt"

# Run Gobuster to find directories
echo "Scanning for directories with Gobuster..."
gobuster dir -u "http://$target" -w /usr/share/Seclists/Discovery/Web-Content/directory-list-2.3-medium.txt -e -x html,php,zip,js > "directories.txt"

# Run Nikto to find vulnerabilities
echo "Scanning for vulnerabilities with Nikto..."
nikto -h "$target" -output "nikto_report.txt"
grep "+ " "nikto_report.txt" | sed 's/+ //g' >> "nikto_report.txt"
echo "Nikto vulnerabilities saved to nikto_report.txt"

# Run WhatWeb to find vulnerabilities
echo "Scanning for vulnerabilities with WhatWeb..."
whatweb "$target" > "whatweb_report.txt"
grep "\[+\]" "whatweb_report.txt" | awk -F ': ' '{print $2}' >> "whatweb_report.txt"
echo "WhatWeb vulnerabilities saved to whatweb_report.txt"

echo -e "${GREEN}#########################################################${NC}"
echo -e "${GREEN}#                                                        #${NC}"
echo -e "${GREEN}#                  TCIrecscan.sh                         #${NC}"
echo -e "${REDIN}#                 SCAN COMPLETED!!!                      #${NC}"
echo -e "${GREEN}#                                                        #${NC}"
echo -e "${GREEN}#########################################################${NC}"
