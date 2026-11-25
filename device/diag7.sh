#!/bin/sh
echo "=== rgds-pad2key: what does it map? ==="
sed -n '1,80p' /usr/bin/rgds-pad2key
echo
echo "=== systray plugin live? ==="
DISPLAY=:0 XAUTHORITY=/home/miyoo/.Xauthority xfconf-query -c xfce4-panel -p /plugins -l 2>&1 | grep -c .
DISPLAY=:0 XAUTHORITY=/home/miyoo/.Xauthority xfconf-query -c xfce4-panel -p /plugins/plugin-6/plugin 2>&1
