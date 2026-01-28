#!/bin/bash
# Xray VLess Management

RED='\e[1;31m'
GREEN='\e[1;32m'
NC='\e[0m'
CONFIG="/etc/xray/config.json"
DOMAIN=$(cat /etc/xray/domain 2>/dev/null || echo "example.com")

function add_vless() {
    clear
    echo -e "${RED}=================================================${NC}"
    echo -e "             CREATE VLESS ACCOUNT                "
    echo -e "${RED}=================================================${NC}"
    read -p "Username : " user
    read -p "Expired (days) : " masaaktif
    read -p "Quota (GB) : " quota

    uuid=$(cat /proc/sys/kernel/random/uuid)
    exp=$(date -d "+${masaaktif} days" +%Y-%m-%d)

    if [[ -f "$CONFIG" ]]; then
        tmp=$(mktemp)
        jq --arg user "$user" --arg uuid "$uuid" \
           '(.inbounds[] | select(.protocol=="vless") | .settings.clients) += [{"id": $uuid, "email": $user}]' \
           "$CONFIG" > "$tmp" && mv "$tmp" "$CONFIG"
    fi

    echo "$user:$exp:$quota" >> /etc/xray/vless_db.txt
    systemctl restart xray 2>/dev/null

    echo -e "VLess Account Created"
    echo -e "Host: $DOMAIN"
    echo -e "User: $user"
    echo -e "UUID: $uuid"
    echo -e "Link: vless://$uuid@$DOMAIN:443?security=tls&encryption=none&type=ws&path=%2Fvless#$user"
}

function trial_vless() {
    clear
    echo -e "Generate Trial VLess"
    user="Trial-$(date +%s | tail -c 4)"
    uuid=$(cat /proc/sys/kernel/random/uuid)

    if [[ -f "$CONFIG" ]]; then
        tmp=$(mktemp)
        jq --arg user "$user" --arg uuid "$uuid" \
           '(.inbounds[] | select(.protocol=="vless") | .settings.clients) += [{"id": $uuid, "email": $user}]' \
           "$CONFIG" > "$tmp" && mv "$tmp" "$CONFIG"
    fi

    systemctl restart xray 2>/dev/null
    echo -e "Trial VLess Created: $user"
}

function renew_vless() {
    clear
    read -p "Username to renew: " user
    read -p "Days to add: " days
    echo "User $user renewed (Mock)"
}

function del_vless() {
    clear
    read -p "Username to delete: " user

    if [[ -f "$CONFIG" ]]; then
        tmp=$(mktemp)
        jq --arg user "$user" \
           '(.inbounds[] | select(.protocol=="vless") | .settings.clients) |= map(select(.email != $user))' \
           "$CONFIG" > "$tmp" && mv "$tmp" "$CONFIG"
    fi
    sed -i "/^$user:/d" /etc/xray/vless_db.txt

    systemctl restart xray 2>/dev/null
    echo "User $user deleted"
}

case $1 in
    add) add_vless ;;
    trial) trial_vless ;;
    renew) renew_vless ;;
    del) del_vless ;;
esac
