#!/bin/bash
# Xray Shadowsocks Management

RED='\e[1;31m'
GREEN='\e[1;32m'
NC='\e[0m'
CONFIG="/etc/xray/config.json"
DOMAIN=$(cat /etc/xray/domain 2>/dev/null || echo "example.com")

function add_shadow() {
    clear
    echo -e "${RED}=================================================${NC}"
    echo -e "             CREATE SHADOW ACCOUNT               "
    echo -e "${RED}=================================================${NC}"
    read -p "Username : " user
    read -p "Expired (days) : " masaaktif

    # SS requires password and method. Assuming AEAD (aes-128-gcm)
    method="aes-128-gcm"
    password=$(cat /proc/sys/kernel/random/uuid | cut -d- -f1) # Short random pass

    if [[ -f "$CONFIG" ]]; then
        tmp=$(mktemp)
        jq --arg user "$user" --arg password "$password" --arg method "$method" \
           '(.inbounds[] | select(.protocol=="shadowsocks") | .settings.clients) += [{"password": $password, "email": $user, "method": $method}]' \
           "$CONFIG" > "$tmp" && mv "$tmp" "$CONFIG"
    fi

    systemctl restart xray 2>/dev/null

    echo -e "Shadowsocks Account Created"
    echo -e "Host: $DOMAIN"
    echo -e "User: $user"
    echo -e "Pass: $password"
    echo -e "Method: $method"

    # Link ss://Base64(method:password@host:port)#user
    raw="${method}:${password}@${DOMAIN}:443"
    enc=$(echo -n $raw | base64 -w 0)
    echo -e "Link: ss://${enc}#${user}"
}

case $1 in
    add) add_shadow ;;
    *) echo "Usage: add" ;;
esac
