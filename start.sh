#!/bin/bash

# Configuration paths
config_ini=/home/root/.cyberghost/config.ini
wireguard_cfg=/home/root/.cyberghost/wg0.conf

# Check if CyberGhost CLI is installed
if [ ! -f "/usr/local/cyberghost/uninstall.sh" ]; then
    echo "Installing CyberGhost CLI..."
    bash /install.sh
fi

# Login if no config exists
if [ ! -f "$config_ini" ]; then
    if [ -n "$ACC" ] && [ -n "$PASS" ]; then
        expect /auth.sh
    else
        echo "Error: Please provide ACC and PASS environment variables"
        exit 1
    fi
fi

# Set default country if not specified
COUNTRY=${COUNTRY:-"US"}
PROTOCOL=${PROTOCOL:-"wireguard"}

# Connect and get WireGuard config
echo "Connecting to CyberGhost VPN..."
sudo cyberghostvpn --connect --country-code "$COUNTRY" --"$PROTOCOL"

# Wait for config generation
sleep 5

# Copy WireGuard config to output location
cat /etc/wireguard/cyberghost.conf
sudo cp /etc/wireguard/cyberghost.conf "$wireguard_cfg"

echo "WireGuard configuration has been generated at $wireguard_cfg"
