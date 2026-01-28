#!/bin/bash

# --- Color Definitions (Luxury/Modern) ---
export COL_NC='\e[0m' # No Color
export COL_WHITE='\e[1;37m'
export COL_BLUE='\e[1;34m'
export COL_CYAN='\e[1;36m'
export COL_GREEN='\e[1;32m'
export COL_RED='\e[1;31m'
export COL_YELLOW='\e[1;33m'
export COL_PURPLE='\e[1;35m'
export COL_GRAY='\e[1;30m'
export COL_BG_BLUE='\e[44m'
export COL_BG_RED='\e[41m'

# --- Helper Functions ---

# Get System Info
function get_system_info() {
    # Public IP (Try to get it, fallback to local if needed)
    # Only fetch if not already set to avoid lag in loop
    if [[ -z "$MYIP" ]]; then
        export MYIP=$(curl -sS ipv4.icanhazip.com 2>/dev/null)
        if [[ -z "$MYIP" ]]; then
            export MYIP=$(hostname -I | awk '{print $1}')
        fi
        if [[ -z "$MYIP" ]]; then export MYIP="127.0.0.1"; fi
    fi

    # Domain - In a real scenario, this might be in a file like /etc/xray/domain
    # We will simulate or read if exists
    if [[ -f /etc/xray/domain ]]; then
        export DOMAIN=$(cat /etc/xray/domain)
    else
        export DOMAIN="vpstunnel.com"
    fi

    # Time
    export TIME=$(date +"%H:%M:%S")
    export DATE=$(date +"%d-%m-%Y")

    # Resource Usage
    export RAM_USAGE=$(free -m | awk '/Mem:/ { print $3 }')
    export RAM_TOTAL=$(free -m | awk '/Mem:/ { print $2 }')
    # CPU Load simulation if top is not standard or restricted
    export CPU_LOAD=$(top -bn1 2>/dev/null | grep load | awk '{printf "%.2f%%", $(NF-2)}')
    if [[ -z "$CPU_LOAD" ]]; then CPU_LOAD="0.5%"; fi
}

# Check Service Status
function check_service() {
    local service_name=$1
    # Check if systemctl exists
    if command -v systemctl &> /dev/null; then
        if systemctl is-active --quiet "$service_name" 2>/dev/null; then
            echo -e "${COL_GREEN}ON${COL_NC} "
        else
            echo -e "${COL_RED}OFF${COL_NC}"
        fi
    else
        # Fallback for non-systemd environments (like this sandbox)
        echo -e "${COL_RED}OFF${COL_NC}"
    fi
}

# Count Accounts (Placeholder logic)
function count_accounts() {
    export SSH_COUNT=$(who | wc -l) # Active SSH sessions
    export OVPN_COUNT=0
    export VMESS_COUNT=0
    export VLESS_COUNT=0
    export TROJAN_COUNT=0
    export SHADOW_COUNT=0
}

# --- Visual Interface ---

function show_logo() {
    clear
    echo -e "${COL_CYAN}"
    echo "  __   __ _____      _  __     __"
    echo "  \ \ / /|  __ \    / \|  \   /  |"
    echo "   \ V / | |__) |  / _ \   \ /   |"
    echo "    > <  |  _  /  / ___ \   V    |"
    echo "   /_/ \_| | \ \ /_/   \_\  |    |"
    echo "         XRAY PREMIUM            "
    echo -e "${COL_NC}"
}

function show_header() {
    echo -e "${COL_BLUE}=======================================================${COL_NC}"
    echo -e "   DATA VPS : ${COL_YELLOW}$MYIP${COL_NC} | ${COL_PURPLE}$DOMAIN${COL_NC}"
    echo -e "   TIME     : ${COL_WHITE}$TIME${COL_NC} | ${COL_WHITE}$DATE${COL_NC}"
    echo -e "${COL_BLUE}=======================================================${COL_NC}"
}

function show_status() {
    # Refresh data
    get_system_info
    count_accounts

    # Get status
    local status_ssh=$(check_service ssh)
    local status_nginx=$(check_service nginx)
    local status_haproxy=$(check_service haproxy)
    local status_wsepro=$(check_service ws-epro)
    local status_xray=$(check_service xray)
    local status_dropbear=$(check_service dropbear)

    echo -e "${COL_BG_BLUE}${COL_WHITE}               SERVICE STATUS INFORMATION              ${COL_NC}"
    # Using printf for better alignment within the status block
    printf " %-20s : %b | %-20s : %b\n" "SSH" "$status_ssh" "NGINX" "$status_nginx"
    printf " %-20s : %b | %-20s : %b\n" "HAPROXY" "$status_haproxy" "WS-ePro" "$status_wsepro"
    printf " %-20s : %b | %-20s : %b\n" "XRAY" "$status_xray" "DROPBEAR" "$status_dropbear"

    echo -e "${COL_BG_RED}${COL_WHITE}                  ACCOUNT INFORMATION                  ${COL_NC}"
    printf " %-20s : %b Account\n" "SSH/OVPN" "${COL_GREEN}$SSH_COUNT${COL_NC}"
    printf " %-20s : %b Account\n" "VMESS" "${COL_GREEN}$VMESS_COUNT${COL_NC}"
    printf " %-20s : %b Account\n" "VLESS" "${COL_GREEN}$VLESS_COUNT${COL_NC}"
    printf " %-20s : %b Account\n" "TROJAN" "${COL_GREEN}$TROJAN_COUNT${COL_NC}"
    printf " %-20s : %b Account\n" "SHADOW" "${COL_GREEN}$SHADOW_COUNT${COL_NC}"
    echo -e "${COL_BLUE}=======================================================${COL_NC}"
}

function show_menu_options() {
    # Define menu items: Number Name
    local menu_items=(
        "01 MENU_SSH_VIP"      "02 MENU_VMESS"
        "03 MENU_VLESS"        "04 MENU_TROJAN"
        "05 MENU_SHADOW"       "06 MENU_TRIAL"
        "07 CEK_RAM/CPU"       "08 DEL_ALL_EXP"
        "25 CHANGE_BANNER"     "09 AUTO_REBOOT"
        "10 MENU_PORT"         "11 SPEEDTEST"
        "12 RUNNING_CEK"       "13 CLEAR_LOG"
        "14 CREATE_SLOW"       "15 BCKP/RSTR"
        "16 REBOOT_VPS"        "17 RESTART_VPS"
        "18 SET_DOMAIN"        "19 CERT_SSL"
        "20 INSTALL_UDP"       "21 CLEAR_CACHE"
        "22 CEK_BANDWITH"      "23 UP_SCRIPT"
        "24 MENU_BOT_VIP"      "26 LOG_CREATE_USER"
        "x EXIT_SCRIPT"
    )

    local num_items=${#menu_items[@]}

    # Loop 2 items at a time
    for ((i=0; i<num_items; i+=2)); do
        local item1="${menu_items[i]}"
        local num1=$(echo "$item1" | awk '{print $1}')
        local name1=$(echo "$item1" | awk '{print $2}' | sed 's/_/ /g')

        local item2="${menu_items[i+1]}"
        local num2=$(echo "$item2" | awk '{print $1}')
        local name2=$(echo "$item2" | awk '{print $2}' | sed 's/_/ /g')

        # Color the brackets and number
        local label1="[${COL_GREEN}$num1${COL_NC}] ${name1}"
        local label2=""
        if [[ -n "$num2" ]]; then
            label2="[${COL_GREEN}$num2${COL_NC}] ${name2}"
        fi

        # Print with padding (approximate width calculation)
        # %b interprets escapes, but sizing is tricky.
        # We manually space it.
        # Length of " [XX] NAME " is roughly 6 + NameLength
        # We aim for ~27 chars per column

        printf " %-35b %-35b\n" "$label1" "$label2"
    done
    echo -e "${COL_BLUE}=======================================================${COL_NC}"
    echo -e " Version      : ${COL_GREEN}V2.4 (Last Update)${COL_NC}"
    echo -e " Status       : ${COL_GREEN}Active${COL_NC}"
    echo -e " Expired      : ${COL_RED}Unknown${COL_NC}"
    echo -e "${COL_BLUE}=======================================================${COL_NC}"
}

# --- Main Logic ---

function main_menu() {
    # Ensure data is gathered before display
    get_system_info
    count_accounts

    while true; do
        show_logo
        show_header
        show_status
        show_menu_options

        echo -ne " ${COL_YELLOW}Select Menu [01-26 or x]: ${COL_NC}"
        read -r selection

        case $selection in
            01|1) echo -e "${COL_CYAN}Opening MENU SSH VIP...${COL_NC}"; sleep 1 ;;
            02|2) echo -e "${COL_CYAN}Opening MENU VMESS...${COL_NC}"; sleep 1 ;;
            03|3) echo -e "${COL_CYAN}Opening MENU VLESS...${COL_NC}"; sleep 1 ;;
            04|4) echo -e "${COL_CYAN}Opening MENU TROJAN...${COL_NC}"; sleep 1 ;;
            05|5) echo -e "${COL_CYAN}Opening MENU SHADOW...${COL_NC}"; sleep 1 ;;
            06|6) echo -e "${COL_CYAN}Opening MENU TRIAL...${COL_NC}"; sleep 1 ;;
            07|7) echo -e "${COL_CYAN}Checking RAM/CPU...${COL_NC}"; echo "RAM: $RAM_USAGE / $RAM_TOTAL"; echo "CPU: $CPU_LOAD"; read -p "Press Enter..." ;;
            08|8) echo -e "${COL_RED}Deleting Expired Accounts...${COL_NC}"; sleep 1 ;;
            25)   echo -e "${COL_CYAN}Changing SSH Banner...${COL_NC}"; sleep 1 ;;
            09|9) echo -e "${COL_RED}Rebooting...${COL_NC}"; sleep 1 ;;
            10)   echo -e "${COL_CYAN}Menu Port...${COL_NC}"; sleep 1 ;;
            11)   echo -e "${COL_CYAN}Running Speedtest...${COL_NC}"; sleep 1 ;;
            12)   echo -e "${COL_CYAN}Running Check...${COL_NC}"; sleep 1 ;;
            13)   echo -e "${COL_CYAN}Clearing Log...${COL_NC}"; sleep 1 ;;
            14)   echo -e "${COL_CYAN}Create Slow...${COL_NC}"; sleep 1 ;;
            15)   echo -e "${COL_CYAN}Backup/Restore...${COL_NC}"; sleep 1 ;;
            16)   echo -e "${COL_RED}Rebooting VPS...${COL_NC}"; sleep 1 ;;
            17)   echo -e "${COL_RED}Restarting VPS Services...${COL_NC}"; sleep 1 ;;
            18)   echo -e "${COL_CYAN}Set Domain...${COL_NC}"; sleep 1 ;;
            19)   echo -e "${COL_CYAN}Cert SSL...${COL_NC}"; sleep 1 ;;
            20)   echo -e "${COL_CYAN}Install UDP...${COL_NC}"; sleep 1 ;;
            21)   echo -e "${COL_CYAN}Clear Cache...${COL_NC}"; sleep 1 ;;
            22)   echo -e "${COL_CYAN}Check Bandwidth...${COL_NC}"; sleep 1 ;;
            23)   echo -e "${COL_CYAN}Update Script...${COL_NC}"; sleep 1 ;;
            24)   echo -e "${COL_CYAN}Menu Bot VIP...${COL_NC}"; sleep 1 ;;
            26)   echo -e "${COL_CYAN}Log Create User Account...${COL_NC}"; sleep 1 ;;
            x|X)  echo -e "${COL_RED}Exiting...${COL_NC}"; exit 0 ;;
            *)    echo -e "${COL_RED}Invalid Selection${COL_NC}"; sleep 1 ;;
        esac
    done
}

# Start
main_menu
