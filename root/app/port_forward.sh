#!/usr/bin/env sh
# Enable port forwarding when using Private Internet Access
# Store forwarded port in /var/run/vpn/vpn_port
sleep 5
client_id=$(head -n 100 /dev/urandom | sha256sum | tr -d " -")
json=$(curl --interface tun0 "http://209.222.18.222:2000/?client_id=$client_id" 2>/dev/null)
[[ -f /var/run/openvpn/vpn_port ]] && rm /var/run/openvpn/vpn_port
if [ "$json" = "" ]; then
    echo '[cont.init.d] [INFO] Port forwarding is already activated on this connection, has expired, or you are not connected to a provider that supports port forwarding'
else
    echo "[cont.init.d] [INFO] Forwarding $json"
    echo "$json" | tr -dc '0-9' | tee /var/run/openvpn/vpn_port
fi
exit 0
