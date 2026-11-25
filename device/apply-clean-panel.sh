#!/bin/sh
# MUST run as miyoo with the session bus.
export DISPLAY=:0
export XAUTHORITY="$HOME/.Xauthority"
export DBUS_SESSION_BUS_ADDRESS="unix:path=/run/user/$(id -u)/bus"
P="$HOME/.config/xfce4/xfconf/xfce-perchannel-xml/xfce4-panel.xml"

echo "=== stop panel + xfconfd (so the file is re-read) ==="
pkill -x xfce4-panel 2>/dev/null
sleep 1
pkill -x xfconfd 2>/dev/null
sleep 2

echo "=== install clean xml ==="
cp -f /tmp/panel-clean.xml "$P"
python3 -c "import xml.etree.ElementTree as ET; ET.parse('$P'); print('  xml ok')"
grep -c 'name="panel-2"' "$P" | sed 's/^/  panel-2 refs: /'

echo
echo "=== start panel ==="
setsid nohup xfce4-panel > "$HOME/panel-final.log" 2>&1 &
sleep 7
pgrep -x xfce4-panel >/dev/null || { echo "  FAILED"; head -20 "$HOME/panel-final.log"; exit 1; }
echo "  ok pid $(pgrep -x xfce4-panel | head -1)"

echo
echo "=== plugins now ==="
for i in $(xfconf-query -c xfce4-panel -p /panels/panel-1/plugin-ids 2>/dev/null | grep -E '^[0-9]+$'); do
    echo "  $i = $(xfconf-query -c xfce4-panel -p /plugins/plugin-$i 2>/dev/null)"
done

echo
echo "=== power manager alive? ==="
pgrep -af xfce4-power-manager | head -2 || echo "  not running"
echo
echo "=== upower battery ==="
upower -i "$(upower -e 2>/dev/null | grep battery | head -1)" 2>/dev/null | grep -E 'state|percentage' | sed 's/^/  /'
echo
echo "=== panel log ==="
grep -viE 'session manager|SESSION_MANAGER' "$HOME/panel-final.log" 2>/dev/null | head -8
