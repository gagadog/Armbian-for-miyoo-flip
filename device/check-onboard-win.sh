#!/bin/sh
export DISPLAY=:0
export XAUTHORITY="$HOME/.Xauthority"

echo "=== onboard options ==="
onboard --help 2>&1 | grep -iE 'size|position|dock|--' | head -25

echo
echo "=== is xwininfo available? ==="
which xwininfo xdotool wmctrl 2>&1

echo
echo "=== screen size ==="
which xrandr >/dev/null 2>&1 && xrandr 2>/dev/null | head -3 || echo "  xrandr missing"

echo
echo "=== onboard window geometry ==="
if command -v xwininfo >/dev/null 2>&1; then
    xwininfo -root -tree 2>/dev/null | grep -iE '"Onboard"|onboard' | head -5
else
    echo "  xwininfo missing, using python Xlib-free approach isn't available either"
fi
