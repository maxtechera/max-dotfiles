#!/bin/bash
# Fix common audio issues on Arch Linux

echo "Fixing audio configuration..."

# Ensure user is in audio group
sudo usermod -aG audio $USER

# Set default sample rate and format
mkdir -p ~/.config/pipewire
cat > ~/.config/pipewire/pipewire.conf << 'EOF'
context.properties = {
    default.clock.rate = 48000
    default.clock.quantum = 1024
    default.clock.min-quantum = 32
    default.clock.max-quantum = 8192
}
EOF

# Copy default configs
sudo cp /usr/share/pipewire/*.conf /etc/pipewire/
sudo cp /usr/share/wireplumber/*.conf /etc/wireplumber/

# Restart audio services
systemctl --user restart pipewire pipewire-pulse wireplumber

echo "Audio should now be working. If not, reboot and check 'wpctl status'"