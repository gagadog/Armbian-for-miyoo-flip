#!/bin/sh
# Add power-manager (battery + brightness) and pulseaudio (volume) to the panel.
export DISPLAY=:0
export XAUTHORITY="$HOME/.Xauthority"
XP="xfconf-query -c xfce4-panel"

echo "=== current plugin ids ==="
IDS=$($XP -p /panels/panel-1/plugin-ids 2>/dev/null | tr '\n' ' ')
echo "  $IDS"

MAX=0
for i in $IDS; do [ "$i" -gt "$MAX" ] 2>/dev/null && MAX=$i; done
echo "  max id: $MAX"

add_plugin() {
    kind="$1"
    new=$((MAX + 1))
    echo "  adding $kind as plugin-$new"
    $XP -p "/plugins/plugin-$new" -n -t string -s "$kind" || return 1
    $XP -p "/panels/panel-1/plugin-ids" -a -t int -s "$new" || return 1
    MAX=$new
}

echo "=== restart xfce4-power-manager ==="
pkill -f xfce4-power-manager 2>/dev/null
sleep 1
setsid nohup xfce4-power-manager > /tmp/xfpm.log 2>&1 &
sleep 3
pgrep -af xfce4-power-manager || echo "  NOT RUNNING"

echo
echo "=== add panel plugins ==="
add_plugin power-manager-plugin
add_plugin pulseaudio-plugin

echo
echo "=== plugin list now ==="
$XP -p /panels/panel-1/plugin-ids 2>/dev/null | tr '\n' ' '
echo

echo "=== restart panel ==="
xfce4-panel -r 2>/dev/null
sleep 4
pgrep -af xfce4-panel | head -2 || echo "  panel not running"

echo
echo "=== resulting types ==="
for i in $($XP -p /panels/panel-1/plugin-ids 2>/dev/null); do
    t=$($XP -p "/plugins/plugin-$i/plugin" 2>/dev/null)
    echo "  $i = $t"
done

echo
echo "=== power manager state ==="
tail -5 /tmp/xfpm.log 2>/dev/null
