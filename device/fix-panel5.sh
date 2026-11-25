#!/bin/sh
# MUST run as miyoo with the session bus.
export DISPLAY=:0
export XAUTHORITY="$HOME/.Xauthority"
export DBUS_SESSION_BUS_ADDRESS="unix:path=/run/user/$(id -u)/bus"
LOG="$HOME/panel-fix2.log"

echo "=== before ==="
xfconf-query -c xfce4-panel -p /panels 2>&1 | head -5

echo
echo "=== stop panel ==="
pkill -x xfce4-panel 2>/dev/null
sleep 1

echo "=== remove panel-2 subtree ==="
xfconf-query -c xfce4-panel -p /panels/panel-2 -r -R 2>&1 | head -3

echo "=== set panels array = [1] ==="
xfconf-query -c xfce4-panel -p /panels -n -t int -s 1 2>&1 | head -3
xfconf-query -c xfce4-panel -p /panels 2>&1 | head -4

echo
echo "=== start panel ==="
: > "$LOG"
setsid nohup xfce4-panel >> "$LOG" 2>&1 &
sleep 6
pgrep -x xfce4-panel >/dev/null || { echo "  FAILED"; head -15 "$LOG"; exit 1; }
echo "  ok pid $(pgrep -x xfce4-panel | head -1)"

echo
echo "=== plugin ids (panel-1) ==="
xfconf-query -c xfce4-panel -p /panels/panel-1/plugin-ids 2>&1 | tr '\n' ' '
echo
echo "=== plugins ==="
for i in $(xfconf-query -c xfce4-panel -p /panels/panel-1/plugin-ids 2>/dev/null | grep -E '^[0-9]+$'); do
    echo "  $i = $(xfconf-query -c xfce4-panel -p /plugins/plugin-$i 2>/dev/null)"
done

echo
echo "=== power manager log ==="
journalctl --user -u xfce4-power-manager -n 10 --no-pager 2>/dev/null | tail -8
tail -8 "$LOG" 2>/dev/null
