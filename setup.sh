#!/bin/bash
# Installer Script for Xray Premium Menu

RED='\e[1;31m'
GREEN='\e[1;32m'
CYAN='\e[1;36m'
NC='\e[0m'

if [ "${EUID}" -ne 0 ]; then
		echo -e "${RED}You need to run this script as root${NC}"
		exit 1
fi

clear
echo -e "${CYAN}=================================================${NC}"
echo -e "           INSTALLER XRAY PREMIUM MENU           "
echo -e "${CYAN}=================================================${NC}"

# 1. Input Domain
echo -e "${GREEN}Input Your Domain (e.g., example.com):${NC}"
read -p "Domain: " domain
if [[ -z "$domain" ]]; then
    echo -e "${RED}Domain cannot be empty!${NC}"
    exit 1
fi

# Prepare Directories
mkdir -p /etc/xray
mkdir -p /var/log/xray
echo "$domain" > /etc/xray/domain
echo -e "${GREEN}Domain saved to /etc/xray/domain${NC}"

# 2. Install Dependencies
echo -e "${CYAN}Installing Dependencies...${NC}"
# Attempt to handle Debian/Ubuntu
apt-get update -y
apt-get install -y jq curl net-tools zip unzip cron speedtest-cli
# Basic Xray installation would go here, assuming pre-installed or adding a one-liner
# bash <(curl -L https://raw.githubusercontent.com/XTLS/Xray-install/main/install-release.sh)

# 3. Move Scripts
echo -e "${CYAN}Installing Menu Scripts...${NC}"
# Assuming scripts are in the current directory
chmod +x menu.sh ssh-vpn.sh xray-vmess.sh xray-vless.sh xray-trojan.sh xray-shadow.sh xp.sh

cp menu.sh /usr/bin/menu
cp ssh-vpn.sh /usr/bin/ssh-vpn.sh
cp xray-vmess.sh /usr/bin/xray-vmess.sh
cp xray-vless.sh /usr/bin/xray-vless.sh
cp xray-trojan.sh /usr/bin/xray-trojan.sh
cp xray-shadow.sh /usr/bin/xray-shadow.sh
cp xp.sh /usr/bin/xp

# 4. Setup Cronjob
echo -e "${CYAN}Setting up Cronjobs...${NC}"
# Delete Expired daily at 00:00
echo "0 0 * * * root /usr/bin/xp" > /etc/cron.d/xp_daily
# Auto Reboot at 05:00
echo "0 5 * * * root reboot" > /etc/cron.d/auto_reboot
chmod 644 /etc/cron.d/xp_daily
chmod 644 /etc/cron.d/auto_reboot
service cron restart 2>/dev/null || systemctl restart cron

# 5. Finalize
echo -e "${CYAN}=================================================${NC}"
echo -e "        INSTALLATION COMPLETED SUCCESSFULLY      "
echo -e "${CYAN}=================================================${NC}"
echo -e "Type ${GREEN}menu${NC} to open the dashboard."
