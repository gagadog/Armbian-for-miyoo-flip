#!/bin/sh
echo "=== uinput ==="
ls -l /dev/uinput 2>&1
echo
echo "=== does rgds-pad2key grab the device? ==="
grep -n -E 'EVIOCGRAB|grab|evdev|InputDevice|/dev/input' /usr/bin/rgds-pad2key 2>/dev/null | head -20
echo
echo "=== which device does it open ==="
echo miyoo | sudo -S ls -l /proc/621/fd 2>/dev/null | grep -E 'input|event' || echo "cannot read fds"
echo
echo "=== is some fd grabbed? /proc/621/status ==="
cat /proc/621/status 2>/dev/null | head -6
echo
echo "=== stop antimicrox and run it in foreground for 8s ==="
pkill -f antimicrox-logged 2>/dev/null
pkill -f 'antimicrox --profile' 2>/dev/null
sleep 1
export DISPLAY=:0
export XAUTHORITY=/home/miyoo/.Xauthority
timeout 8 antimicrox --profile /home/miyoo/.config/antimicrox/profiles/miyoo-mouse.amgp > /tmp/amx.out 2>&1
echo "exit=$?"
echo "--- stdout/stderr ---"
cat /tmp/amx.out | head -40
