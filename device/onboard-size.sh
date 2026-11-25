#!/bin/sh
export DISPLAY=:0
export XAUTHORITY="$HOME/.Xauthority"

ARGS="-s 640x220 -x 0 -y 250"

cat > /home/miyoo/.config/autostart/onboard.desktop <<EOF
[Desktop Entry]
Type=Application
Name=Onboard
Comment=On-screen keyboard
Exec=onboard $ARGS
Icon=onboard
Terminal=false
X-GNOME-Autostart-enabled=true
EOF

cat > /home/miyoo/Desktop/onboard.desktop <<EOF
[Desktop Entry]
Type=Application
Name=Onboard
Comment=On-screen keyboard
Exec=onboard $ARGS
Icon=onboard
Terminal=false
EOF
chmod +x /home/miyoo/Desktop/onboard.desktop
chown 1000:1000 /home/miyoo/.config/autostart/onboard.desktop /home/miyoo/Desktop/onboard.desktop

echo "=== restart onboard with the new size ==="
pkill -x onboard 2>/dev/null
sleep 2
su - miyoo -c "DISPLAY=:0 XAUTHORITY=/home/miyoo/.Xauthority setsid nohup onboard $ARGS > /tmp/onboard3.out 2>&1 &"
sleep 6
pgrep -a onboard || echo "NOT RUNNING"
echo "--- stderr ---"
head -6 /tmp/onboard3.out 2>/dev/null
echo
echo "=== antimicrox also started? ==="
pgrep -af 'antimicrox' || echo "  not running (autostart will handle it next boot)"
