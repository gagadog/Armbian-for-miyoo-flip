#!/bin/sh
set -e
echo "=== install debs ==="
dpkg -i /tmp/debs/*.deb 2>&1 | grep -E 'Setting up|Errors|error|depends' | head -20
echo
echo "=== dependency check ==="
dpkg -C 2>&1 | head -5 || echo "  no broken packages"
python3 -c "import pyatspi; print('  pyatspi ok')" 2>&1 | tail -2

echo
echo "=== autostart: onboard + antimicrox ==="
mkdir -p /home/miyoo/.config/autostart

cat > /home/miyoo/.config/autostart/onboard.desktop <<'EOF'
[Desktop Entry]
Type=Application
Name=Onboard
Comment=On-screen keyboard
Exec=onboard
Icon=onboard
Terminal=false
X-GNOME-Autostart-enabled=true
EOF

cat > /home/miyoo/.config/autostart/antimicrox.desktop <<'EOF'
[Desktop Entry]
Type=Application
Name=AntiMicroX
Comment=Gamepad mapper (not mapped by default; miyoo-padmouse handles the mouse)
Exec=/home/miyoo/.local/bin/antimicrox-logged
Icon=antimicrox
Terminal=false
X-GNOME-Autostart-enabled=true
EOF

chown -R 1000:1000 /home/miyoo/.config/autostart
ls -l /home/miyoo/.config/autostart/

echo
echo "=== start onboard now (as miyoo, on :0) ==="
su - miyoo -c "DISPLAY=:0 XAUTHORITY=/home/miyoo/.Xauthority setsid nohup onboard > /tmp/onboard2.out 2>&1 &"
sleep 6
pgrep -a onboard || echo "NOT RUNNING"
echo "--- onboard stderr ---"
cat /tmp/onboard2.out 2>/dev/null | head -10
echo
echo "=== window present? ==="
DISPLAY=:0 XAUTHORITY=/home/miyoo/.Xauthority xwininfo -root -tree 2>/dev/null | grep -i -E 'onboard' | head -5 || echo "  (no xwininfo)"
