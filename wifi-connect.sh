#!/bin/bash
# Simple WiFi connection helper for Arch ISO

echo "=== WiFi Connection Helper ==="
echo

# Check if already connected
if ping -c 1 google.com &> /dev/null; then
    echo "✓ Already connected to internet!"
    exit 0
fi

# Start iwctl and show instructions
echo "Starting WiFi setup..."
echo
echo "Commands to use in iwctl:"
echo "1. device list                    (see your WiFi device, usually wlan0)"
echo "2. station wlan0 scan             (scan for networks)"
echo "3. station wlan0 get-networks     (list available networks)"
echo "4. station wlan0 connect \"Name\"   (connect to your network)"
echo "5. exit                           (leave iwctl)"
echo
echo "Starting iwctl..."
echo

iwctl

# Test connection
echo
echo "Testing connection..."
if ping -c 1 google.com &> /dev/null; then
    echo "✓ Successfully connected!"
else
    echo "✗ Connection failed. Try again."
fi