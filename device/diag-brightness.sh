#!/bin/sh
echo "=== backlight device ==="
ls -l /sys/class/backlight/
cat /sys/class/backlight/backlight/brightness 2>/dev/null
cat /sys/class/backlight/backlight/max_brightness 2>/dev/null

echo
echo "=== logind session / seat ==="
loginctl list-sessions 2>&1 | head -5
loginctl show-session "$(loginctl list-sessions --no-legend 2>/dev/null | awk 'NR==1{print $1}')" -p Id -p Seat -p Active -p Type -p Remote 2>&1

echo
echo "=== logind SetBrightness works? ==="
SID=$(loginctl list-sessions --no-legend 2>/dev/null | awk 'NR==1{print $1}')
busctl call org.freedesktop.login1 /org/freedesktop/login1 \
    org.freedesktop.login1.Manager GetSession "s" "$SID" >/dev/null 2>&1 \
    && echo "  manager ok" || echo "  manager call failed"
busctl call org.freedesktop.login1 "/org/freedesktop/login1/session/$SID" \
    org.freedesktop.login1.Session SetBrightness "ssu" backlight backlight 100 2>&1 | head -3
echo "  brightness now: $(cat /sys/class/backlight/backlight/brightness 2>/dev/null)"

echo
echo "=== upower backlight support ==="
upower --dump 2>/dev/null | grep -iE 'daemon|on battery|Backlight' | head -5

echo
echo "=== xfce4-power-manager journal ==="
journalctl --user-unit xfce4-power-manager -n 20 --no-pager 2>/dev/null | tail -12
grep -iE 'backlight' /home/miyoo/.local/share/xfce4-power-manager/*.log 2>/dev/null | head -5

echo
echo "=== xfpm settings ==="
su - miyoo -c 'export DISPLAY=:0 XAUTHORITY=$HOME/.Xauthority DBUS_SESSION_BUS_ADDRESS=unix:path=/run/user/1000/bus
xfconf-query -c xfce4-power-manager -l 2>/dev/null | grep -iE "brightness|dpms" | head -8
'
