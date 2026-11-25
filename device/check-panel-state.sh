#!/bin/sh
P=/home/miyoo/.config/xfce4/xfconf/xfce-perchannel-xml/xfce4-panel.xml
echo "=== file on disk ==="
ls -l "$P"
grep -c 'plugin-12' "$P" 2>/dev/null || true
awk '/name="plugin-ids"/{i=1;next} i&&/<value type="int"/{n++} i&&/<\/property>/{print "  ids count: "n; exit}' "$P"
echo
echo "=== live channel ==="
su - miyoo -c 'export DISPLAY=:0 XAUTHORITY=$HOME/.Xauthority DBUS_SESSION_BUS_ADDRESS=unix:path=/run/user/1000/bus
xfconf-query -c xfce4-panel -p /panels/panel-1/plugin-ids 2>&1 | tr "\n" " "; echo
echo "  plugin-12 prop: $(xfconf-query -c xfce4-panel -p /plugins/plugin-12 2>&1)"
echo "  plugin-11 prop: $(xfconf-query -c xfce4-panel -p /plugins/plugin-11 2>&1)"
'
echo
echo "=== pnmixer running? ==="
pgrep -af pnmixer | head -2
