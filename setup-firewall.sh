#!/bin/bash
# SIMPLE SETUP FIREWALL SCRIPT
# 
# Function to set up firewall rules with ufw
setup_ufw() {
    local firewall_rules_file="$1"

    if [ ! -f "$firewall_rules_file" ]; then
        echo "Error: File $firewall_rules_file not found!"
        return 1
    fi

    ufw status | grep -q "Status: inactive" && ufw --force enable

    while IFS= read -r line || [ -n "$line" ]; do
        if [[ "$line" =~ ^#.*$ ]] || [ -z "$line" ]; then
            continue
        fi

        IFS=";" read -r subnets ports_protocols <<< "$line"
        IFS="," read -r -a ports_protocols_list <<< "$ports_protocols"

        for port_protocol in "${ports_protocols_list[@]}"; do
            IFS=":" read -r port protocol <<< "$port_protocol"
            for subnet in $(echo "$subnets" | tr "," "\n"); do
                if [ "$protocol" == "any" ]; then
                    echo "Allowing all protocols for $port from $subnet"
                    ufw allow from "$subnet" to any port "$port"
                else
                    echo "Allowing $protocol for $port from $subnet"
                    ufw allow proto "$protocol" from "$subnet" to any port "$port"
                fi
            done
        done
    done < "$firewall_rules_file"

    ufw reload
    echo "UFW setup completed."
}

# Function to set up firewall rules with firewalld
setup_firewalld() {
    local firewall_rules_file="$1"

    if [ ! -f "$firewall_rules_file" ]; then
        echo "Error: File $firewall_rules_file not found!"
        return 1
    fi

    if ! systemctl is-active --quiet firewalld; then
        echo "Starting firewalld..."
        systemctl start firewalld
    fi

    firewall-cmd --reload

    while IFS= read -r line || [ -n "$line" ]; do
        if [[ "$line" =~ ^#.*$ ]] || [ -z "$line" ]; then
            continue
        fi

        IFS=";" read -r subnets ports_protocols <<< "$line"
        IFS="," read -r -a ports_protocols_list <<< "$ports_protocols"

        for port_protocol in "${ports_protocols_list[@]}"; do
            IFS=":" read -r port protocol <<< "$port_protocol"
            for subnet in $(echo "$subnets" | tr "," "\n"); do
                if [ "$protocol" == "any" ]; then
                    echo "Allowing all protocols for $port from $subnet"
                    firewall-cmd --zone=public --add-rich-rule="rule family='ipv4' source address='$subnet' port port='$port' protocol='any' accept"
                else
                    echo "Allowing $protocol for $port from $subnet"
                    firewall-cmd --zone=public --add-rich-rule="rule family='ipv4' source address='$subnet' port port='$port' protocol='$protocol' accept"
                fi
            done
        done
    done < "$firewall_rules_file"

    firewall-cmd --runtime-to-permanent
    echo "Firewalld setup completed."
}

# Function to handle invalid firewall type
handle_invalid_fw() {
    echo "Error: Invalid firewall type. Use 'ufw', 'firewalld', or 'none'."
    exit 1
}

# Default values
firewall_type="none"
firewall_rules_file="conf/firewall_params.conf"

# Parse command-line arguments
while [[ $# -gt 0 ]]; do
    case $1 in
        --fw=*)
            firewall_type="${1#*=}"
            shift
            ;;
        --file=*)
            firewall_rules_file="${1#*=}"
            shift
            ;;
        *)
            echo "Usage: $0 [--fw=ufw|firewalld|none] [--file=rules_file]"
            echo "Sample rules file: conf/firewall_params.conf"
            exit 1
            ;;
    esac
done

# Main logic
case "$firewall_type" in
    ufw)
        setup_ufw "$firewall_rules_file"
        ;;
    firewalld)
        setup_firewalld "$firewall_rules_file"
        ;;
    none)
        echo "No firewall setup selected."
        ;;
    *)
        handle_invalid_fw
        ;;
esac