#!/bin/bash
set -e

echo "=== install pnmixer ==="
dpkg -i /tmp/pnmixer.deb /tmp/libnotify4.deb 2>&1 | grep -E 'Setting up|error|depends' | head -6
command -v pnmixer

echo
echo "=== autostart entry ==="
cat > /etc/xdg/autostart/pnmixer.desktop <<'EOF'
[Desktop Entry]
Type=Application
Name=PNMixer
Comment=Volume control in the system tray
Exec=pnmixer
Icon=pnmixer
Terminal=false
NoDisplay=true
EOF
ls -l /etc/xdg/autostart/pnmixer.desktop

echo
echo "=== apply the panel config without the pulse plugin ==="
install -m 644 -o 1000 -g 1000 /tmp/panel-nopulse.xml \
    /home/miyoo/.config/xfce4/xfconf/xfce-perchannel-xml/xfce4-panel.xml
grep -c 'plugin-12' /home/miyoo/.config/xfce4/xfconf/xfce-perchannel-xml/xfce4-panel.xml || true

echo
echo "=== volume desktop icons ==="
for spec in "up:5%+:音量 +:audio-volume-high" "down:5%-:音量 -:audio-volume-low"; do
    key=$(echo "$spec" | cut -d: -f1)
    arg=$(echo "$spec" | cut -d: -f2)
    name=$(echo "$spec" | cut -d: -f3)
    icon=$(echo "$spec" | cut -d: -f4)
    cat > "/home/miyoo/Desktop/volume-$key.desktop" <<EOF
[Desktop Entry]
Type=Application
Name=$name
Exec=wpctl set-volume @DEFAULT_AUDIO_SINK@ $arg
Icon=$icon
Terminal=false
EOF
    chmod 755 "/home/miyoo/Desktop/volume-$key.desktop"
done
chown 1000:1000 /home/miyoo/Desktop/volume-*.desktop
ls /home/miyoo/Desktop/ | sed 's/^/  /'

echo
echo "=== restart session ==="
systemctl restart lightdm
sleep 20

echo "=== verify ==="
pgrep -af 'xfce4-panel|pnmixer|xfce4-power-manager|nm-applet' | head -6
echo "--- panel ids ---"
sudo -u miyoo DISPLAY=:0 XAUTHORITY=/home/miyoo/.Xauthority \
    DBUS_SESSION_BUS_ADDRESS=unix:path=/run/user/1000/bus \
    xfconf-query -c xfce4-panel -p /panels/panel-1/plugin-ids 2>&1 | tr '\n' ' '
echo
echo "--- panel still alive after 10 more seconds? ---"
sleep 10
pgrep -x xfce4-panel >/dev/null && echo "  yes, pid $(pgrep -x xfce4-panel | head -1)" || echo "  NO - panel died"
