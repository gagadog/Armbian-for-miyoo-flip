#!/bin/bash
# Restart the display manager so XFCE starts fresh with the clean panel config.
echo "=== before ==="
pgrep -af 'lightdm|xfce4-session|xfce4-panel' | head -6

echo
echo "=== restart lightdm ==="
systemctl restart lightdm
sleep 18

echo
echo "=== after ==="
pgrep -af 'lightdm|xfce4-session|xfce4-panel' | head -8

echo
echo "=== panel plugins as seen in the new session ==="
sudo -u miyoo DISPLAY=:0 XAUTHORITY=/home/miyoo/.Xauthority \
    DBUS_SESSION_BUS_ADDRESS=unix:path=/run/user/1000/bus \
    xfconf-query -c xfce4-panel -p /panels/panel-1/plugin-ids 2>&1 | tr '\n' ' '
echo
for i in 11 12; do
    echo "  plugin-$i = $(sudo -u miyoo DISPLAY=:0 XAUTHORITY=/home/miyoo/.Xauthority DBUS_SESSION_BUS_ADDRESS=unix:path=/run/user/1000/bus xfconf-query -c xfce4-panel -p /plugins/plugin-$i 2>&1)"
done

echo
echo "=== session journal (panel/plugin errors) ==="
journalctl -b --no-pager -n 60 2>/dev/null | grep -iE 'xfce4-panel|powermanager|pulseaudio-plugin|Unable to load' | tail -12
