#!/bin/bash


if grep -qs "^nogroup:" /etc/group; then
		NOGROUP=nogroup
	else
		NOGROUP=nobody
	fi

if [ ${3} = true ]; then
	gateway='push "redirect-gateway def1 bypass-dhcp"'
else
	gateway=""
fi

config_content="port ${1}4
proto ${2}
dev tun
topology subnet
server 10.8.0.0 255.255.255.0

user nobody
group ${NOGROUP}

# Certificates
ca /opt/certs/ca/CA.pem
cert /opt/certs/server/server.crt
key /opt/certs/server/server.key
dh /opt/certs/server/dh.pem

# TLS and Cipher
auth SHA256
tls-server
#data-ciphers-fallback AES-256-GCM AES-128-GCM
#data-ciphers AES-256-GCM
data-ciphers AES-256-GCM:AES-128-GCM
tls-version-min 1.2
tls-cipher TLS-ECDHE-ECDSA-WITH-AES-128-GCM-SHA256
tls-auth /opt/certs/server/tls-auth.key 0

keepalive 10 120
resolv-retry infinite
persist-key
persist-tun
verb 3
explicit-exit-notify 1
ifconfig-pool-persist /opt/openvpn/ipp.txt
client-config-dir /opt/openvpn/ccd
${gateway}
"
# Write the configuration content to the OpenVPN configuration file
echo "$config_content" > /opt/openvpn/server.conf
echo "server.conf generated with successfull"