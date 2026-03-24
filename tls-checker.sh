#!/bin/bash

# TLS Certificate Checker TUI
# Usage: ./tls-checker.sh

# Colors
RED='\033[0;31m'
GREEN='\033[0;32m'
YELLOW='\033[1;33m'
BLUE='\033[0;34m'
CYAN='\033[0;36m'
NC='\033[0m' # No Color
BOLD='\033[1m'

clear_screen() {
    clear
}

print_header() {
    echo -e "${CYAN}╔════════════════════════════════════════════════════════════╗${NC}"
    echo -e "${CYAN}║${NC}         ${BOLD}TLS Certificate Checker${NC}                            ${CYAN}║${NC}"
    echo -e "${CYAN}╚════════════════════════════════════════════════════════════╝${NC}"
    echo ""
}

print_separator() {
    echo -e "${BLUE}────────────────────────────────────────────────────────────────${NC}"
}

extract_host_port() {
    local url="$1"
    # Remove protocol if present
    url="${url#https://}"
    url="${url#http://}"
    # Remove path
    url="${url%%/*}"
    # Extract host and port
    if [[ "$url" == *":"* ]]; then
        HOST="${url%%:*}"
        PORT="${url##*:}"
    else
        HOST="$url"
        PORT="443"
    fi
}

check_certificate() {
    local host="$1"
    local port="$2"
    
    echo -e "\n${YELLOW}⏳ Checking certificate for ${BOLD}${host}:${port}${NC}...\n"
    print_separator
    
    # Get certificate info
    cert_output=$(curl -Ivs "https://${host}:${port}/" 2>&1 | grep -E '^\*\s+(subject|issuer|start date|expire date|SSL certificate|SSL connection|subjectAltName)' | head -20)
    
    if [[ -z "$cert_output" ]]; then
        echo -e "${RED}❌ Failed to retrieve certificate. Trying direct OpenSSL connection...${NC}\n"
        cert_output=$(echo | openssl s_client -servername "$host" -connect "${host}:${port}" 2>/dev/null)
        if [[ $? -ne 0 ]] || [[ -z "$cert_output" ]]; then
            echo -e "${RED}❌ Could not connect to ${host}:${port}${NC}"
            return 1
        fi
        # Parse openssl output
        echo "$cert_output" | openssl x509 -noout -dates -subject -issuer 2>/dev/null
        return
    fi
    
    # Parse and display results
    while IFS= read -r line; do
        if [[ "$line" == *"subject:"* ]]; then
            echo -e "${BOLD}📋 Subject:${NC} ${line#*subject: }"
        elif [[ "$line" == *"issuer:"* ]]; then
            echo -e "${BOLD}🏢 Issuer:${NC}  ${line#*issuer: }"
        elif [[ "$line" == *"start date:"* ]]; then
            echo -e "${BOLD}📅 Valid From:${NC} ${line#*start date: }"
        elif [[ "$line" == *"expire date:"* ]]; then
            expire_date="${line#*expire date: }"
            echo -e "${BOLD}📅 Valid Until:${NC} ${expire_date}"
            # Check expiry
            expire_epoch=$(date -j -f "%b %d %H:%M:%S %Y %Z" "$expire_date" "+%s" 2>/dev/null || date -d "$expire_date" "+%s" 2>/dev/null)
            current_epoch=$(date "+%s")
            if [[ -n "$expire_epoch" ]]; then
                days_left=$(( (expire_epoch - current_epoch) / 86400 ))
                if [[ $days_left -lt 0 ]]; then
                    echo -e "${RED}⚠️  EXPIRED ${days_left#-} days ago!${NC}"
                elif [[ $days_left -lt 30 ]]; then
                    echo -e "${YELLOW}⚠️  Expires in ${days_left} days${NC}"
                else
                    echo -e "${GREEN}✅ Expires in ${days_left} days${NC}"
                fi
            fi
        elif [[ "$line" == *"SSL connection using"* ]]; then
            echo -e "${BOLD}🔐 TLS:${NC}     ${line#*SSL connection using }"
        elif [[ "$line" == *"SSL certificate verify ok"* ]]; then
            echo -e "\n${GREEN}✅ Certificate verification: OK${NC}"
        elif [[ "$line" == *"SSL certificate verify"* ]]; then
            echo -e "\n${RED}❌ Certificate verification: FAILED${NC}"
        fi
    done <<< "$cert_output"
    
    print_separator
}

main_menu() {
    while true; do
        clear_screen
        print_header
        
        echo -e "${BOLD}Enter a URL or hostname to check its TLS certificate${NC}"
        echo -e "${CYAN}Examples:${NC}"
        echo "  • example.com"
        echo "  • https://example.com/path/"
        echo "  • example.com:8443"
        echo ""
        echo -e "Type ${YELLOW}'q'${NC} or ${YELLOW}'quit'${NC} to exit"
        echo ""
        print_separator
        echo ""
        
        read -p "🔗 Enter URL: " url_input
        
        # Check for quit (compatible with older bash)
        url_lower=$(echo "$url_input" | tr '[:upper:]' '[:lower:]')
        if [[ "$url_lower" == "q" ]] || [[ "$url_lower" == "quit" ]] || [[ "$url_lower" == "exit" ]]; then
            echo -e "\n${GREEN}Goodbye!${NC}\n"
            exit 0
        fi
        
        # Validate input
        if [[ -z "$url_input" ]]; then
            echo -e "${RED}Please enter a valid URL${NC}"
            sleep 1
            continue
        fi
        
        # Extract host and port
        extract_host_port "$url_input"
        
        # Check certificate
        check_certificate "$HOST" "$PORT"
        
        echo ""
        read -p "Press Enter to continue..." 
    done
}

# Run main menu
main_menu
