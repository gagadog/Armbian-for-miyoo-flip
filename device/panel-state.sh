#!/bin/sh
P=/home/miyoo/.config/xfce4/xfconf/xfce-perchannel-xml/xfce4-panel.xml
echo "=== plugin ids in xml ==="
sed -n '/name="plugin-ids"/,/<\/property>/p' "$P" | head -20
echo
echo "=== plugin type declarations ==="
grep -oE 'name="plugin-[0-9]+" type="string" value="[^"]+"' "$P" | head -20
echo
echo "=== panel process args ==="
pgrep -af xfce4-panel | head -3
echo
echo "=== xfconf read check (raw) ==="
DISPLAY=:0 XAUTHORITY=/home/miyoo/.Xauthority xfconf-query -c xfce4-panel -p /plugins/plugin-11 2>&1 | head -3
DISPLAY=:0 XAUTHORITY=/home/miyoo/.Xauthority xfconf-query -c xfce4-panel -p /plugins/plugin-12 2>&1 | head -3
echo
echo "=== all /plugins children ==="
DISPLAY=:0 XAUTHORITY=/home/miyoo/.Xauthority xfconf-query -c xfce4-panel -p /plugins -l 2>&1 | head -30
