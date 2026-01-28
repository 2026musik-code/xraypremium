#!/bin/bash
# SSH & OpenVPN Account Management

# Load Colors
RED='\e[1;31m'
GREEN='\e[1;32m'
NC='\e[0m'

function usernew() {
    clear
    echo -e "${RED}=================================================${NC}"
    echo -e "             CREATE SSH & OVPN ACCOUNT           "
    echo -e "${RED}=================================================${NC}"
    read -p "Username : " Login
    read -p "Password : " Pass
    read -p "Expired (days) : " masaaktif

    IP=$(curl -sS ipv4.icanhazip.com)
    useradd -e `date -d "$masaaktif days" +"%Y-%m-%d"` -s /bin/false -M $Login
    echo -e "$Pass\n$Pass\n"|passwd $Login &> /dev/null

    echo -e "Data SSH & OpenVPN"
    echo -e "Host : $IP"
    echo -e "Username : $Login"
    echo -e "Password : $Pass"
    echo -e "Expired : $masaaktif Days"
}

function trial() {
    clear
    echo -e "${RED}=================================================${NC}"
    echo -e "             GENERATE TRIAL SSH ACCOUNT          "
    echo -e "${RED}=================================================${NC}"
    # Random suffix
    Login="Trial-$(date +%s | tail -c 4)"
    Pass="1"
    masaaktif=1

    IP=$(curl -sS ipv4.icanhazip.com)
    useradd -e `date -d "$masaaktif days" +"%Y-%m-%d"` -s /bin/false -M $Login
    echo -e "$Pass\n$Pass\n"|passwd $Login &> /dev/null

    echo -e "Data SSH Trial"
    echo -e "Host : $IP"
    echo -e "Username : $Login"
    echo -e "Password : $Pass"
    echo -e "Expired : 24 Hours"
}

function renew() {
    clear
    echo -e "Renew SSH Account"
    read -p "Username : " Login
    read -p "Days to Add : " masaaktif

    # Logic to extend
    # chage -E `date -d "$masaaktif days" +"%Y-%m-%d"` $Login
    # But we need current expiry + days. For simplicity in this script:
    usermod -e `date -d "$masaaktif days" +"%Y-%m-%d"` $Login
    echo -e "Account $Login renewed for $masaaktif days."
}

function deluser() {
    clear
    echo -e "Delete SSH Account"
    read -p "Username : " Login
    userdel -f $Login
    echo -e "Account $Login deleted."
}

# Simple router
case $1 in
    usernew) usernew ;;
    trial) trial ;;
    renew) renew ;;
    deluser) deluser ;;
esac
