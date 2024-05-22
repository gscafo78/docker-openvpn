#!/bin/bash


SERVER_IP=$(curl -s ifconfig.io)

CERT_VAR=$(cat /opt/certs/client/client.crt)
KEY_VAR=$(cat /opt/certs/client/client.key)
CA_VAR=$(cat /opt/certs/ca/CA.pem)
TLS_VAR=$(cat /opt/certs/server/tls-auth.key)
SERVER_NAME=$(cat /opt/certs/server/server.crt | grep "Subject: CN=" | sed 's/.*Subject: CN=\([^,]*\).*/\1/')
CLIENT_NAME=$(cat /opt/certs/client/client.crt | grep "Subject: CN=" | sed 's/.*Subject: CN=\([^,]*\).*/\1/')
PORT_NUMBER=$(grep -E "^port [0-9]+" "/opt/openvpn/server.conf" | awk '{print $2}')
PORT_PROTO=$(grep -E "^proto " "/opt/openvpn/server.conf" | awk '{print $2}')

config_content="client
proto ${PORT_PROTO}4
remote $SERVER_IP $PORT_NUMBER
dev tun
#topology subnet
auth SHA256
#data-ciphers-fallback AES-128-GCM
data-ciphers AES-256-GCM:AES-128-GCM
tls-version-min 1.2
verify-x509-name $SERVER_NAME name
tls-client
ignore-unknown-option block-outside-dns
setenv opt block-outside-dns
tls-cipher TLS-ECDHE-ECDSA-WITH-AES-128-GCM-SHA256
keepalive 10 120
resolv-retry infinite
nobind
explicit-exit-notify
persist-key
persist-tun
verb 3

<ca>
$CA_VAR
</ca>

<cert>
$CERT_VAR
</cert>

<key>
$KEY_VAR
</key>

key-direction 1
<tls-auth>
$TLS_VAR
</tls-auth>
"
# Write the configuration content to the OpenVPN configuration file
echo "$config_content" > /opt/openvpn/${CLIENT_NAME}.ovpn
echo "${CLIENT_NAME}.ovpn generated with successfull"