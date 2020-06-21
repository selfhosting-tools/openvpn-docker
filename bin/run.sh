#!/bin/sh

set -e
set -x

mkdir -p /dev/net
if [ ! -c /dev/net/tun ]; then
    mknod /dev/net/tun c 10 200
fi

VPN_IP_POOL=$(cat /etc/openvpn/server.conf | grep '^server' | awk '{print $2}')
ETH0_IP=$(ip address show dev eth0 | grep inet | awk '{print $2}' | cut -d/ -f 1)

# Masquerade trafic from VPN
iptables -t nat -A POSTROUTING -s $VPN_IP_POOL/24 -o eth0 -j SNAT --to-source $ETH0_IP

exec openvpn \
    --cd /etc/openvpn/ \
    --script-security 2 \
    --up /usr/local/bin/openvpn_up.sh \
    --config server.conf
