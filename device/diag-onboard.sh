#!/bin/sh
echo "=== onboard installed? ==="
which onboard; onboard --version 2>&1 | head -2
echo
echo "=== deps ==="
python3 -c "import gi; print('python3-gi ok')" 2>&1
python3 -c "import gi; gi.require_version('Gtk','3.0'); from gi.repository import Gtk; print('gtk3 ok')" 2>&1
dpkg -l 2>/dev/null | grep -E 'gir1.2-gtk|python3-gi|onboard' | awk '{print "  "$2" "$3}'
echo
echo "=== run it for 8s and capture stderr ==="
pkill -f onboard 2>/dev/null || true
sleep 1
su - miyoo -c "DISPLAY=:0 XAUTHORITY=/home/miyoo/.Xauthority timeout 8 onboard > /tmp/onboard.out 2>&1" || echo "exit=$?"
echo "--- output ---"
cat /tmp/onboard.out
echo
echo "=== windows after run (any onboard window?) ==="
su - miyoo -c "DISPLAY=:0 XAUTHORITY=/home/miyoo/.Xauthority xwininfo -root -tree 2>/dev/null" | grep -i -E 'onboard|keyboard' | head -5 || echo "  (xwininfo unavailable or no window)"
echo
echo "=== config dir ==="
ls -la /home/miyoo/.config/onboard 2>/dev/null || echo "  no config yet"
