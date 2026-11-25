#!/bin/bash
set -e
echo "=== purge the broken pulseaudio panel plugin ==="
systemctl stop lightdm
sleep 2
pkill -x xfconfd 2>/dev/null || true
sleep 1
dpkg --purge xfce4-pulseaudio-plugin 2>&1 | grep -E 'Removing|Purging|error' | head -5
dpkg -l xfce4-pulseaudio-plugin 2>/dev/null | grep '^ii' || echo "  package gone"

echo
echo "=== remove any leftover plugin-12 from the config ==="
P=/home/miyoo/.config/xfce4/xfconf/xfce-perchannel-xml/xfce4-panel.xml
grep -c 'plugin-12' "$P" || true
python3 - "$P" <<'PY'
import re, sys
p = sys.argv[1]
s = open(p).read()
s2 = re.sub(r'\n {4}<property name="plugin-12"[^\n]*', '', s)
s2 = re.sub(r'\n {8}<value type="int" value="12"/>', '', s2)
open(p, "w").write(s2)
print("  cleaned" if s2 != s else "  nothing to clean")
PY

echo
echo "=== tidy up the debug leftovers ==="
rm -f /home/miyoo/xfce4-panel.xml.broken /home/miyoo/panel-fix.log \
      /home/miyoo/panel-final.log /home/miyoo/panel.log 2>/dev/null || true
ls /home/miyoo/ | grep -E 'panel|xfce4' || echo "  clean"

echo
echo "=== start session ==="
systemctl start lightdm
sleep 20
pgrep -af 'xfce4-panel|pnmixer|xfce4-power-manager|nm-applet' | head -6
echo "--- ids ---"
sudo -u miyoo DISPLAY=:0 XAUTHORITY=/home/miyoo/.Xauthority \
    DBUS_SESSION_BUS_ADDRESS=unix:path=/run/user/1000/bus \
    xfconf-query -c xfce4-panel -p /panels/panel-1/plugin-ids 2>&1 | tr '\n' ' '
echo
sleep 10
pgrep -x xfce4-panel >/dev/null && echo "  panel alive" || echo "  panel DEAD"
