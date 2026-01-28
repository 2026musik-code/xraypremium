#!/bin/bash
# Xray VMess Management

RED='\e[1;31m'
GREEN='\e[1;32m'
NC='\e[0m'
CONFIG="/etc/xray/config.json"
DOMAIN=$(cat /etc/xray/domain 2>/dev/null || echo "example.com")

function add_vmess() {
    clear
    echo -e "${RED}=================================================${NC}"
    echo -e "             CREATE VMESS ACCOUNT                "
    echo -e "${RED}=================================================${NC}"
    read -p "Username : " user
    read -p "Expired (days) : " masaaktif
    read -p "Quota (GB) : " quota

    # Check if user exists (mock check)
    if grep -q "$user" "$CONFIG"; then
        echo "User already exists."
        exit 1
    fi

    uuid=$(cat /proc/sys/kernel/random/uuid)
    exp=$(date -d "+${masaaktif} days" +%Y-%m-%d)

    # Add to Xray Config using JQ
    # Assuming the first inbound is VMess or searching for it.
    # For simplicity/robustness, we read the config to a temp file then move it.

    # Simulation of JQ addition
    # .inbounds[] | select(.protocol=="vmess") | .settings.clients += [{"id": "$uuid", "email": "$user"}]

    if [[ -f "$CONFIG" ]]; then
        tmp=$(mktemp)
        jq --arg user "$user" --arg uuid "$uuid" \
           '(.inbounds[] | select(.protocol=="vmess") | .settings.clients) += [{"id": $uuid, "email": $user}]' \
           "$CONFIG" > "$tmp" && mv "$tmp" "$CONFIG"
    else
        echo "Config file not found, creating mock entry..."
    fi

    # Record Metadata (Expiry, Quota)
    echo "$user:$exp:$quota" >> /etc/xray/vmess_db.txt

    # Restart Service
    systemctl restart xray 2>/dev/null

    # Show Output
    echo -e "VMess Account Created"
    echo -e "Host: $DOMAIN"
    echo -e "User: $user"
    echo -e "UUID: $uuid"
    echo -e "Exp : $exp"
    echo -e "Quota: $quota GB"

    # Generate Link (vmess://...)
    # Base64 encode json
    json_config="{\"v\":\"2\",\"ps\":\"$user\",\"add\":\"$DOMAIN\",\"port\":\"443\",\"id\":\"$uuid\",\"aid\":\"0\",\"net\":\"ws\",\"type\":\"none\",\"host\":\"$DOMAIN\",\"path\":\"/vmess\",\"tls\":\"tls\"}"
    vmess_link="vmess://$(echo -n $json_config | base64 -w 0)"
    echo -e "Link: $vmess_link"
}

function trial_vmess() {
    clear
    echo -e "Generate Trial VMess"
    user="Trial-$(date +%s | tail -c 4)"
    masaaktif=1
    uuid=$(cat /proc/sys/kernel/random/uuid)
    exp=$(date -d "+1 days" +%Y-%m-%d)

    # Add to config
    if [[ -f "$CONFIG" ]]; then
        tmp=$(mktemp)
        jq --arg user "$user" --arg uuid "$uuid" \
           '(.inbounds[] | select(.protocol=="vmess") | .settings.clients) += [{"id": $uuid, "email": $user}]' \
           "$CONFIG" > "$tmp" && mv "$tmp" "$CONFIG"
    fi

    systemctl restart xray 2>/dev/null

    echo -e "Trial Created: $user"
    echo -e "Expired: 24 Hours"
}

function renew_vmess() {
    clear
    read -p "Username to renew: " user
    read -p "Days to add: " days

    # Update DB
    # Implementation simplified
    echo "User $user renewed for $days days (Mock)"
}

function del_vmess() {
    clear
    read -p "Username to delete: " user

    # Remove from config
    if [[ -f "$CONFIG" ]]; then
        tmp=$(mktemp)
        jq --arg user "$user" \
           '(.inbounds[] | select(.protocol=="vmess") | .settings.clients) |= map(select(.email != $user))' \
           "$CONFIG" > "$tmp" && mv "$tmp" "$CONFIG"
    fi

    # Remove from DB
    sed -i "/^$user:/d" /etc/xray/vmess_db.txt

    systemctl restart xray 2>/dev/null
    echo "User $user deleted"
}

case $1 in
    add) add_vmess ;;
    trial) trial_vmess ;;
    renew) renew_vmess ;;
    del) del_vmess ;;
esac
