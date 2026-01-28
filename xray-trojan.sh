#!/bin/bash
# Xray Trojan Management

RED='\e[1;31m'
GREEN='\e[1;32m'
NC='\e[0m'
CONFIG="/etc/xray/config.json"
DOMAIN=$(cat /etc/xray/domain 2>/dev/null || echo "example.com")

function add_trojan() {
    clear
    echo -e "${RED}=================================================${NC}"
    echo -e "             CREATE TROJAN ACCOUNT               "
    echo -e "${RED}=================================================${NC}"
    read -p "Username : " user
    read -p "Expired (days) : " masaaktif
    read -p "Quota (GB) : " quota

    # Trojan uses password, usually same as user or distinct
    # For simplicity we use user as password or ask.
    # Usually in auto scripts, user == password for trojan to be simple.
    password="$user"

    exp=$(date -d "+${masaaktif} days" +%Y-%m-%d)

    if [[ -f "$CONFIG" ]]; then
        tmp=$(mktemp)
        jq --arg user "$user" --arg password "$password" \
           '(.inbounds[] | select(.protocol=="trojan") | .settings.clients) += [{"password": $password, "email": $user}]' \
           "$CONFIG" > "$tmp" && mv "$tmp" "$CONFIG"
    fi

    echo "$user:$exp:$quota" >> /etc/xray/trojan_db.txt
    systemctl restart xray 2>/dev/null

    echo -e "Trojan Account Created"
    echo -e "Host: $DOMAIN"
    echo -e "User: $user"
    echo -e "Link: trojan://$password@$DOMAIN:443?security=tls&type=tcp&headerType=none#$user"
}

function trial_trojan() {
    clear
    echo -e "Generate Trial Trojan"
    user="Trial-$(date +%s | tail -c 4)"
    password="$user"

    if [[ -f "$CONFIG" ]]; then
        tmp=$(mktemp)
        jq --arg user "$user" --arg password "$password" \
           '(.inbounds[] | select(.protocol=="trojan") | .settings.clients) += [{"password": $password, "email": $user}]' \
           "$CONFIG" > "$tmp" && mv "$tmp" "$CONFIG"
    fi

    systemctl restart xray 2>/dev/null
    echo -e "Trial Trojan Created: $user"
}

function renew_trojan() {
    clear
    read -p "Username to renew: " user
    read -p "Days to add: " days
    echo "User $user renewed (Mock)"
}

function del_trojan() {
    clear
    read -p "Username to delete: " user

    if [[ -f "$CONFIG" ]]; then
        tmp=$(mktemp)
        jq --arg user "$user" \
           '(.inbounds[] | select(.protocol=="trojan") | .settings.clients) |= map(select(.email != $user))' \
           "$CONFIG" > "$tmp" && mv "$tmp" "$CONFIG"
    fi
    sed -i "/^$user:/d" /etc/xray/trojan_db.txt

    systemctl restart xray 2>/dev/null
    echo "User $user deleted"
}

case $1 in
    add) add_trojan ;;
    trial) trial_trojan ;;
    renew) renew_trojan ;;
    del) del_trojan ;;
esac
