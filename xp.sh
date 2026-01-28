#!/bin/bash
# XP.sh - Auto Delete Expired Accounts

RED='\e[1;31m'
GREEN='\e[1;32m'
NC='\e[0m'

# Helper to check expiration
function check_expired_xray() {
    local protocol=$1 # vmess, vless, trojan
    local db_file="/etc/xray/${protocol}_db.txt"
    local script_name="xray-${protocol}.sh"

    if [[ ! -f "$db_file" ]]; then
        return
    fi

    today=$(date -d "0 days" +"%Y-%m-%d")

    # Read DB file line by line
    while IFS=":" read -r user exp quota; do
        # Check if line is empty
        if [[ -z "$user" ]]; then continue; fi

        # Compare dates
        d1=$(date -d "$exp" +%s)
        d2=$(date -d "$today" +%s)

        if [[ $d2 -ge $d1 ]]; then
            echo -e "${RED}Deleting Expired $protocol User: $user${NC}"
            # Call the delete function from the management script
            # We assume the management scripts are in path
            echo "$user" | $script_name del > /dev/null 2>&1

            # Also remove from DB line (handled by script usually, but verify)
        else
            echo -e "${GREEN}User $user Active until $exp${NC}"
        fi
    done < "$db_file"
}

function check_expired_ssh() {
    echo "Checking SSH Accounts..."
    today=$(date +%s)

    # Iterate through system users with expiration set
    # awk to get users with shadow expiry
    # simpler: useradd -e sets account expiration. `chage -l user` shows it.

    # We will loop through users with UID >= 1000
    for user in $(awk -F: '$3 >= 1000 && $1 != "nobody" {print $1}' /etc/passwd); do
        exp_date=$(chage -l $user | grep "Account expires" | cut -d: -f2)
        if [[ "$exp_date" != " never" ]]; then
            exp_sec=$(date -d "$exp_date" +%s)
            if [[ $today -ge $exp_sec ]]; then
                echo -e "${RED}Deleting Expired SSH User: $user${NC}"
                userdel -f "$user"
            fi
        fi
    done
}

echo "======================================="
echo "   Auto Delete Expired Accounts"
echo "======================================="

check_expired_xray "vmess"
check_expired_xray "vless"
check_expired_xray "trojan"
check_expired_xray "shadow"
check_expired_ssh

echo "======================================="
echo "   Cleanup Complete"
echo "======================================="
