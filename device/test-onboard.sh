#!/bin/sh
# Run as miyoo (has the X session). Not via sudo.
export DISPLAY=:0
export XAUTHORITY="$HOME/.Xauthority"

pkill -x onboard 2>/dev/null
sleep 1

echo "=== run onboard 10s, capture stderr ==="
timeout 10 onboard > "$HOME/onboard.out" 2>&1
echo "rc=$?"
echo "--- output ---"
cat "$HOME/onboard.out"
echo
echo "=== still running? ==="
pgrep -a onboard || echo "  not running"
echo
echo "=== onboard config ==="
ls -la "$HOME/.config/onboard" 2>/dev/null || echo "  none"
echo
echo "=== keyboard layout / settings ==="
cat "$HOME/.config/onboard/onboard-settings.ini" 2>/dev/null | head -20 || echo "  no settings file"
