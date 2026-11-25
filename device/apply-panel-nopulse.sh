#!/bin/bash
set -e

echo "=== install panel xml ==="
install -m 644 -o 1000 -g 1000 /tmp/panel-nopulse.xml \
    /home/miyoo/.config/xfce4/xfconf/xfce-perchannel-xml/xfce4-panel.xml
grep -c 'plugin-12' /home/miyoo/.config/xfce4/xfconf/xfce-perchannel-xml/xfce4-panel.xml || true

echo "=== volume desktop icons ==="
cat > /home/miyoo/Desktop/volume-up.desktop <<'EOF'
[Desktop Entry]
Type=Application
Name=音量 +
Exec=wpctl set-volume @DEFAULT_AUDIO_SINK@ 5%+
Icon=audio-volume-high
Terminal=false
EOF
cat > /home/miyoo/Desktop/volume-down.desktop <<'EOF'
[Desktop Entry]
Type=Application
Name=音量 -
Exec=wpctl set-volume @DEFAULT_AUDIO_SINK@ 5%-
Icon=audio-volume-low
Terminal=false
EOF
chmod 755 /home/miyoo/Desktop/volume-*.desktop
chown 1000:1000 /home/miyoo/Desktop/volume-*.desktop
ls -l /home/miyoo/Desktop/ | grep volume

echo
echo "=== restart session ==="
systemctl restart lightdm
sleep 18

echo "=== verify ==="
pgrep -af 'xfce4-panel|xfce4-power-manager|nm-applet' | head -5
echo "--- panel ids ---"
sudo -u miyoo DISPLAY=:0 XAUTHORITY=/home/miyoo/.Xauthority \
    DBUS_SESSION_BUS_ADDRESS=unix:path=/run/user/1000/bus \
    xfconf-query -c xfce4-panel -p /panels/panel-1/plugin-ids 2>&1 | tr '\n' ' '
echo
echo "--- journal errors ---"
journalctl -b --no-pager -n 40 2>/dev/null | grep -iE 'Unable to load|xfce4-panel.*error|segfault' | tail -6 || echo "  none"
