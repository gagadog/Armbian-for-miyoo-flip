#!/bin/sh
# MUST run as the desktop user (miyoo), not root.
export DISPLAY=:0
export XAUTHORITY="$HOME/.Xauthority"
export DBUS_SESSION_BUS_ADDRESS="unix:path=/run/user/$(id -u)/bus"
LOG="$HOME/panel-fix.log"

echo "=== panels in channel ==="
xfconf-query -c xfce4-panel -p /panels 2>&1 | head -5

echo
echo "=== stop panel + reset channel ==="
pkill -x xfce4-panel 2>/dev/null
sleep 1
cp -f "$HOME/.config/xfce4/xfconf/xfce-perchannel-xml/xfce4-panel.xml" \
      "$HOME/xfce4-panel.xml.broken" 2>/dev/null
xfconf-query -c xfce4-panel -p / -r -R 2>&1 | head -3
sleep 1
echo "  after reset:"; xfconf-query -c xfce4-panel -p /panels 2>&1 | head -3

echo
echo "=== start panel ==="
: > "$LOG"
setsid nohup xfce4-panel >> "$LOG" 2>&1 &
sleep 6
pgrep -x xfce4-panel >/dev/null || { echo "  FAILED"; head -20 "$LOG"; exit 1; }
echo "  ok, pid $(pgrep -x xfce4-panel | head -1)"

echo
echo "=== ids ==="
xfconf-query -c xfce4-panel -p /panels/panel-1/plugin-ids 2>/dev/null | tee /tmp/ids.txt | tr '\n' ' '
echo
IDS=$(grep -E '^[0-9]+$' /tmp/ids.txt | tr '\n' ' ')
MAX=0
for i in $IDS; do [ "$i" -gt "$MAX" ] && MAX=$i; done
echo "  max=$MAX"

echo
echo "=== append plugins ==="
P1=$((MAX + 1)); P2=$((MAX + 2))
xfconf-query -c xfce4-panel -p "/plugins/plugin-$P1" -n -t string -s power-manager-plugin || exit 1
xfconf-query -c xfce4-panel -p "/plugins/plugin-$P2" -n -t string -s pulseaudio-plugin || exit 1
SET=""
for i in $IDS; do SET="$SET -t int -s $i"; done
SET="$SET -t int -s $P1 -t int -s $P2"
# shellcheck disable=SC2086
xfconf-query -c xfce4-panel -p /panels/panel-1/plugin-ids -n $SET || exit 1

echo
echo "=== restart panel ==="
xfce4-panel -r 2>/dev/null
sleep 6
pgrep -x xfce4-panel >/dev/null || { echo "  DIED"; tail -20 "$LOG"; exit 1; }
echo "  ok"

echo
echo "=== final plugin list ==="
for i in $(xfconf-query -c xfce4-panel -p /panels/panel-1/plugin-ids 2>/dev/null | grep -E '^[0-9]+$'); do
    echo "  $i = $(xfconf-query -c xfce4-panel -p /plugins/plugin-$i 2>/dev/null)"
done

echo
echo "=== logind lid ==="
systemctl show systemd-logind 2>/dev/null | grep -i '^HandleLidSwitch' | sed 's/^/  /'
echo
echo "=== panel log tail ==="
tail -6 "$LOG" 2>/dev/null
