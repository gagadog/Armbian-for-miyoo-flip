#!/bin/bash
set -e
P=/home/miyoo/.config/xfce4/xfconf/xfce-perchannel-xml/xfce4-panel.xml

echo "=== 1. stop the whole session (xfconfd flushes on exit) ==="
systemctl stop lightdm
sleep 3
pkill -x xfconfd 2>/dev/null || true
pkill -x xfce4-panel 2>/dev/null || true
sleep 2

echo "=== 2. now write the clean config ==="
install -m 644 -o 1000 -g 1000 /tmp/panel-nopulse.xml "$P"
grep -c 'plugin-12' "$P" || true
awk '/name="plugin-ids"/{i=1;next} i&&/<value type="int"/{n++} i&&/<\/property>/{print "  ids: "n; exit}' "$P"

echo "=== 3. start the session ==="
systemctl start lightdm
sleep 22

echo "=== 4. verify ==="
pgrep -af 'xfce4-panel|pnmixer|xfce4-power-manager|nm-applet' | head -6
echo "--- file after session start ---"
grep -c 'plugin-12' "$P" || true
awk '/name="plugin-ids"/{i=1;next} i&&/<value type="int"/{n++} i&&/<\/property>/{print "  ids: "n; exit}' "$P"
echo "--- live channel ---"
sudo -u miyoo DISPLAY=:0 XAUTHORITY=/home/miyoo/.Xauthority \
    DBUS_SESSION_BUS_ADDRESS=unix:path=/run/user/1000/bus \
    xfconf-query -c xfce4-panel -p /panels/panel-1/plugin-ids 2>&1 | tr '\n' ' '
echo
echo "--- wait 15s, is the panel still alive? ---"
sleep 15
pgrep -x xfce4-panel >/dev/null && echo "  YES pid $(pgrep -x xfce4-panel | head -1)" || echo "  NO - died"
