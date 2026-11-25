#!/bin/sh
# MUST run as the desktop user (miyoo), not root.
export DISPLAY=:0
export XAUTHORITY="$HOME/.Xauthority"
export DBUS_SESSION_BUS_ADDRESS="unix:path=/run/user/$(id -u)/bus"

echo "=== env check ==="
echo "  user=$(id -un) display=$DISPLAY dbus=$DBUS_SESSION_BUS_ADDRESS"
xfconf-query -c xfce4-panel -p /panels 2>&1 | head -3

echo
echo "=== stop panel, reset the whole channel ==="
pkill -x xfce4-panel 2>/dev/null
sleep 1
cp -f "$HOME/.config/xfce4/xfconf/xfce-perchannel-xml/xfce4-panel.xml" \
      "$HOME/xfce4-panel.xml.broken" 2>/dev/null
xfconf-query -c xfce4-panel -r -R 2>&1 | head -3
sleep 1

echo
echo "=== start panel (regenerates defaults) ==="
setsid nohup xfce4-panel > /tmp/panel.log 2>&1 &
sleep 6
if ! pgrep -x xfce4-panel >/dev/null; then
    echo "  PANEL FAILED TO START"
    head -20 /tmp/panel.log
    exit 1
fi
echo "  panel running: $(pgrep -x xfce4-panel | head -1)"

echo
echo "=== default plugin-ids ==="
xfconf-query -c xfce4-panel -p /panels/panel-1/plugin-ids 2>/dev/null | tee /tmp/ids.txt | tr '\n' ' '
echo

IDS=$(grep -E '^[0-9]+$' /tmp/ids.txt | tr '\n' ' ')
MAX=0
for i in $IDS; do [ "$i" -gt "$MAX" ] && MAX=$i; done
echo "  max id: $MAX"

echo
echo "=== append power-manager + pulseaudio ==="
P1=$((MAX + 1)); P2=$((MAX + 2))
xfconf-query -c xfce4-panel -p "/plugins/plugin-$P1" -n -t string -s power-manager-plugin || exit 1
xfconf-query -c xfce4-panel -p "/plugins/plugin-$P2" -n -t string -s pulseaudio-plugin || exit 1

SET=""
for i in $IDS; do SET="$SET -t int -s $i"; done
SET="$SET -t int -s $P1 -t int -s $P2"
# shellcheck disable=SC2086
xfconf-query -c xfce4-panel -p /panels/panel-1/plugin-ids -n $SET || exit 1
echo "  ids now:"
xfconf-query -c xfce4-panel -p /panels/panel-1/plugin-ids 2>/dev/null | tr '\n' ' '
echo

echo
echo "=== restart panel ==="
xfce4-panel -r 2>/dev/null
sleep 6
if ! pgrep -x xfce4-panel >/dev/null; then
    echo "  PANEL DIED AFTER RESTART"
    tail -20 /tmp/panel.log
    exit 1
fi
echo "  panel ok: $(pgrep -x xfce4-panel | head -1)"

echo
echo "=== final plugins ==="
for i in $(xfconf-query -c xfce4-panel -p /panels/panel-1/plugin-ids 2>/dev/null | grep -E '^[0-9]+$'); do
    echo "  $i = $(xfconf-query -c xfce4-panel -p /plugins/plugin-$i 2>/dev/null)"
done

echo
echo "=== logind lid handling ==="
systemctl show systemd-logind 2>/dev/null | grep -i '^HandleLidSwitch' | sed 's/^/  /'
