#!/bin/sh
echo "=== panel alive? ==="
pgrep -af xfce4-panel | head -3 || echo "  PANEL NOT RUNNING"
echo
echo "=== panel log ==="
grep -viE 'session manager|SESSION_MANAGER' "$HOME/panel-final.log" 2>/dev/null | tail -20
echo
echo "=== ldd libpulseaudio-plugin.so (missing deps) ==="
ldd /usr/lib/aarch64-linux-gnu/xfce4/panel/plugins/libpulseaudio-plugin.so 2>&1 | grep -i 'not found' || echo "  all present"
echo
echo "=== ldd libxfce4powermanager.so (missing deps) ==="
ldd /usr/lib/aarch64-linux-gnu/xfce4/panel/plugins/libxfce4powermanager.so 2>&1 | grep -i 'not found' || echo "  all present"
echo
echo "=== pulse server reachable as miyoo? ==="
su - miyoo -c 'export XDG_RUNTIME_DIR=/run/user/$(id -u); pactl info 2>&1 | head -4 || echo "  pactl missing"'
echo
echo "=== pipewire-pulse running? ==="
pgrep -af 'pipewire-pulse' | head -2 || echo "  not running"
ls -l /run/user/1000/pulse/native 2>&1
