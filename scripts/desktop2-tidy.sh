#!/bin/bash
# Post-stage2 tidy-up: drop the hand-written panel layout so XFCE generates its
# own known-good default on first login (640x480 has no room for guessing), and
# make sure the profile is owned correctly.
set -e
UH=/mnt/miyoo-root/home/miyoo
rm -f "$UH/.config/xfce4/xfconf/xfce-perchannel-xml/xfce4-panel.xml"
echo "panel xml: $(ls "$UH/.config/xfce4/xfconf/xfce-perchannel-xml/" 2>/dev/null || echo none)"

# keep the desktop shortcut executable and trusted
chmod +x "$UH/Desktop/onboard.desktop" 2>/dev/null || true
chown -R 1000:1000 "$UH"
ls -la "$UH/.config/autostart/" "$UH/Desktop/" 2>/dev/null
