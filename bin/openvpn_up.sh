#!/bin/sh

set -e
set -x

echo "Running openvpn_up.sh..."

ETH0_IP=$(ip address show dev eth0 | grep inet | awk '{print $2}' | cut -d/ -f 1)

# Setup port forwarding
if [ -e "/etc/openvpn/port_forwarding.conf" ]; then
    echo "Configuring port forwarding..."

    # Masquerade source IP for packets coming from outside
    VPN_INTERFACE=$(cat /etc/openvpn/server.conf | grep '^dev' | awk '{print $2}')
    VPN_INTERFACE_IP=$(ip address show dev $VPN_INTERFACE | grep inet | awk '{print $2}' | cut -d/ -f 1)
    iptables -t nat -A POSTROUTING -o $VPN_INTERFACE -j SNAT --to-source $VPN_INTERFACE_IP

    cat "/etc/openvpn/port_forwarding.conf" | while read line
    do
        # Line format is: CLIENT_IP PROTOCOL SRC_PORT [DEST_PORT]
        CLIENT_IP=$(echo "$line" | awk '{print $1}')
        PROTOCOL=$(echo "$line" | awk '{print $2}')
        SRC_PORT=$(echo "$line" | awk '{print $3}')
        DEST_PORT=$(echo "$line" | awk '{print $4}')
        if [ -z "$DEST_PORT" ]; then
            DEST_PORT=$SRC_PORT
        fi
        iptables \
            -t nat -A PREROUTING \
            -d $ETH0_IP \
            -p $PROTOCOL --dport $SRC_PORT \
            -j DNAT --to-destination $CLIENT_IP:$DEST_PORT
        echo "Port forward added: $PROTOCOL/$SRC_PORT -> $CLIENT_IP:$DEST_PORT"
    done
fi

echo "openvpn_up.sh done"
