#!/bin/sh
echo "=== backlight ==="
ls -l /sys/class/backlight/*/brightness 2>&1
cat /sys/class/backlight/backlight/max_brightness 2>&1
cat /sys/class/backlight/backlight/brightness 2>&1
echo "-- read/write as miyoo? --"
if [ -w /sys/class/backlight/backlight/brightness ]; then echo "writable by miyoo"; else echo "NOT writable by miyoo"; fi
brightnessctl --version 2>&1 | head -1
brightnessctl -l 2>&1 | head -6
echo
echo "=== vulkan ==="
vulkaninfo --summary 2>&1 | head -35
echo
echo "=== GL renderer (needs DISPLAY) ==="
DISPLAY=:0 XAUTHORITY=/home/miyoo/.Xauthority glxinfo -B 2>&1 | grep -iE 'renderer|OpenGL version|device' | head -6
echo
echo "=== panfrost in use? ==="
echo miyoo | sudo -S dmesg 2>/dev/null | grep -i -E 'panfrost|mali' | head -6
