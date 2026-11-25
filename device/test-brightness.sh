#!/bin/sh
echo "=== graphical session (seat0) ==="
SID=$(loginctl list-sessions --no-legend 2>/dev/null | awk '$4=="seat0"{print $1; exit}')
echo "  session: $SID"
loginctl show-session "$SID" -p Id -p Seat -p Active -p Type 2>&1 | sed 's/^/  /'

echo
echo "=== SetBrightness on that session ==="
echo "  before: $(cat /sys/class/backlight/backlight/brightness)"
busctl call org.freedesktop.login1 "/org/freedesktop/login1/session/$SID" \
    org.freedesktop.login1.Session SetBrightness "ssu" backlight backlight 150 2>&1 | head -2
sleep 1
echo "  after : $(cat /sys/class/backlight/backlight/brightness)"

echo
echo "=== also try 60 ==="
busctl call org.freedesktop.login1 "/org/freedesktop/login1/session/$SID" \
    org.freedesktop.login1.Session SetBrightness "ssu" backlight backlight 60 2>&1 | head -2
sleep 1
echo "  after : $(cat /sys/class/backlight/backlight/brightness)"

echo
echo "=== restore a comfortable level ==="
echo 120 > /sys/class/backlight/backlight/brightness
cat /sys/class/backlight/backlight/brightness

echo
echo "=== who is the panel's session? ==="
PID=$(pgrep -x xfce4-panel | head -1)
echo "  panel pid: $PID"
loginctl session-status "$(loginctl list-sessions --no-legend | awk -v p="$PID" '$4=="seat0"' | awk 'NR==1{print $1}')" 2>/dev/null | head -6

echo
echo "=== brightnessctl as miyoo ==="
su - miyoo -c 'brightnessctl set 100; brightnessctl -l | head -3' 2>&1 | head -5
