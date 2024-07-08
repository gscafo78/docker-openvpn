#!/bin/bash

# Exit immediately if any command exits with a non-zero status
set -e

# Function to get the default gateway interface
get_default_gateway_interface() {
    local default_interface
    default_interface=$(ip route | grep '^default' | awk '{print $5}' | head -n1)
    if [ -n "$default_interface" ]; then
        echo "$default_interface"
    else
        echo "No default gateway interface found" >&2
        return 1
    fi
}

# Function to check if a string is a valid port number
is_valid_port() {
    local port=$1
    if [[ $port =~ ^[0-9]+$ && $port -ge 1 && $port -le 65353 ]]; then
        return 0  # True
    else
        return 1  # False
    fi
}

# Function to check if a string is a valid protocol
is_valid_protocol() {
    local protocol=$(echo "$1" | tr '[:upper:]' '[:lower:]')
    if [[ "$protocol" == "tcp" || "$protocol" == "udp" ]]; then
        return 0  # True
    else
        return 1  # False
    fi
}

get_port_number() {
    local config_file="$1"
    local port_number=$(grep -Po '^port\s+\K\d+' "$config_file")
    echo "$port_number"
}

# Add iptables rules
update_iptables_forward() {
    local nic=$1
    local port=$2
    local dst=10.8.0.2    
    # Enable IPv4 forwarding
    echo 1 > /proc/sys/net/ipv4/ip_forward
    echo "IPv4 forwarding enabled"
    # Set iptables rules
    if [ -n "$nic" ]; then
        iptables -t nat -I POSTROUTING 1 -s 10.8.0.0/24 -o "$nic" -j MASQUERADE
        iptables -I INPUT 1 -i tun0 -j ACCEPT
        iptables -I FORWARD 1 -i "$nic" -o tun0 -j ACCEPT
        iptables -I FORWARD 1 -i tun0 -o "$nic" -j ACCEPT
        iptables -I INPUT 1 -i "$nic" -p udp --dport $port -j ACCEPT
        if [ "${FORWARD}" = true ]; then
            iptables -t nat -I PREROUTING 1 -p tcp -i $nic --dport 1:64000 -j DNAT --to-destination $dst:1-64000
            iptables -t nat -I PREROUTING 1 -p udp -i $nic --dport 1:64000 -j DNAT --to-destination $dst:1-64000
        fi
    else
        echo "Failed to obtain default gateway interface" >&2
    fi
}

# Cleanup iptables
restore_iptables() {
    local nic=$1
    local port=$2
    local dst=10.8.0.2
    echo "Restoring iptables rules for $nic"
    iptables -t nat -D POSTROUTING -s 10.8.0.0/24 -o "$nic" -j MASQUERADE
    iptables -D INPUT -i tun0 -j ACCEPT
    iptables -D FORWARD -i "$nic" -o tun0 -j ACCEPT
    iptables -D FORWARD -i tun0 -o "$nic" -j ACCEPT
    iptables -D INPUT -i "$nic" -p udp --dport $port -j ACCEPT
    if [ "${FORWARD}" = true ]; then
        iptables -t nat -D PREROUTING -p tcp -i $nic --dport 1:64000 -j DNAT --to-destination $dst:1-64000
        iptables -t nat -D PREROUTING -p udp -i $nic --dport 1:64000 -j DNAT --to-destination $dst:1-64000
    fi
    echo 0 > /proc/sys/net/ipv4/ip_forward
}

# Function to check and create folder
check_and_create_folder() {
    local folder_path="$1"
    if [ -d "$folder_path" ]; then
        echo "The folder '$folder_path' already exists."
    else
        echo "The folder '$folder_path' does not exist. Creating now..."
        mkdir -p "$folder_path"
        if [ $? -eq 0 ]; then
            echo "The folder '$folder_path' has been created successfully."
        else
            echo "Failed to create the folder '$folder_path'."
            exit 1
        fi
    fi
}

# Define directories for CA and certificates
cafolder=/opt/certs/ca
certsfolder=/opt/certs/client
certsserver=/opt/certs/server
openvpnfolder=/opt/openvpn
NIC=$(get_default_gateway_interface)

# Trap SIGTERM and SIGINT signals to call restore_iptables
trap 'restore_iptables "$NIC"; exit' SIGTERM SIGINT

# Check and create each folder
check_and_create_folder "$openvpnfolder/ccd"

if is_valid_port "$SERVER_PORT"; then
    echo "$SERVER_PORT - Valid port number!"
else
    echo "Invalid port number. Please enter a number between 1 and 65353."
    exit 0
fi

if is_valid_protocol "$SERVER_PROTO"; then
    echo "$SERVER_PROTO - Valid transport protocol!"
else
    echo "Invalid transport protocol. Please enter either TCP or UDP."
    exit 0
fi

checkfileconf() {
    local filetype="$1"
    # Check if there are any .conf or ovpn files in the directory
    if [ -z "$(ls -A /opt/openvpn/*.${filetype} 2>/dev/null)" ]; then
        echo "No ${filetype} files found. Please run docker run --rm -v your_path:/opt -e GENERATE_SERVER=true 4ss078/openvpn"
        return 1
    else
        echo "${filetype} file found. Ok"
        return 0
    fi
}

case "${GENERATE_SERVER}" in
    true)
        if [ ! -f "${certsserver}/tls-auth.key" ]; then
            openvpn --genkey secret "${certsserver}/tls-auth.key"
            echo "tls-auth-key generated successfully"
        else
            echo "tls-auth-key found, ok"
        fi        
        /generateserver.sh ${SERVER_PORT} ${SERVER_PROTO} ${REDIRECT_GATEWAY}
        ;;
esac

case "${GENERATE_CLIENT}" in
    true)
        /generateclient.sh
        ;;
esac

if [ "${GENERATE_SERVER}" = false ] && [ "${REDIRECT_GATEWAY}" = true ]; then
    echo "To enable redirect gateway you have to generate new server conf file. ex -e GENERATE_SERVER = true -e REDIRECT_GATEWAY = true"
    exit 0
fi

if [ "${RUN_SERVER}" = true ] || [ "${RUN_CLIENT}" = true ]; then
    if checkfileconf "conf"; then
        if [ "${RUN_SERVER}" = true ]; then
            check_and_create_folder "$cafolder"
            check_and_create_folder "$certsfolder"
            check_and_create_folder "$certsserver"
            # config_file="/opt/openvpn/server.conf"
            # vpnport=$(get_port_number "$config_file")
            # update_iptables_forward "$NIC" "$vpnport"

            # Loop through and run openvpn for each .conf file
            for conf in /opt/openvpn/*.conf; do
                vpnport=$(get_port_number "$config_file")
                update_iptables_forward "$NIC" "$vpnport"
                /usr/sbin/openvpn --config "$conf" &
            done
        fi
    fi

    if checkfileconf "ovpn"; then
        if [ "${RUN_CLIENT}" = true ]; then
            # Loop through and run openvpn for each .ovpn file
            for conf in /opt/openvpn/*.ovpn; do
                /usr/sbin/openvpn --config "$conf" &
            done
        fi
    fi
fi

# Wait for all background processes to finish
wait

# Cleanup iptables rules on normal script exit
if [ "${RUN_SERVER}" = "true" ]; then
    restore_iptables "$NIC" "$vpnport"
fi

# Start the application passed as arguments to the script
exec "$@"
