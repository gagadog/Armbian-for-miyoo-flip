#!/bin/sh
export DISPLAY=:0
export XAUTHORITY="$HOME/.Xauthority"

echo "=== 1. logind 重新加载（让 HandleLidSwitch=ignore 生效）==="
systemctl restart systemd-logind 2>&1 | head -3
sleep 2
systemctl show systemd-logind -p HandleLidSwitch 2>&1 | head -2
loginctl show-session "$XDG_SESSION_ID" -p Id 2>/dev/null | head -2

echo
echo "=== 2. 停面板，重置整个 xfce4-panel 通道 ==="
pkill -x xfce4-panel 2>/dev/null
sleep 1
cp -f "$HOME/.config/xfce4/xfconf/xfce-perchannel-xml/xfce4-panel.xml" \
      "$HOME/xfce4-panel.xml.broken" 2>/dev/null
xfconf-query -c xfce4-panel -r -R 2>&1 | head -3
sleep 1

echo
echo "=== 3. 启动面板让它生成默认配置 ==="
setsid nohup xfce4-panel > /tmp/panel.log 2>&1 &
sleep 5
pgrep -af xfce4-panel | head -2 || { echo "  PANEL FAILED"; cat /tmp/panel.log | head -20; exit 1; }

echo
echo "=== 4. 读默认 plugin-ids ==="
IDS=$(xfconf-query -c xfce4-panel -p /panels/panel-1/plugin-ids 2>/dev/null | tr -d 'Value is an array with' | tr '\n' ' ')
echo "  ids: $IDS"
MAX=0
for i in $IDS; do
    case "$i" in ''|*[!0-9]*) continue;; esac
    [ "$i" -gt "$MAX" ] && MAX=$i
done
echo "  max: $MAX"

echo
echo "=== 5. 追加 power-manager + pulseaudio ==="
P1=$((MAX + 1)); P2=$((MAX + 2))
xfconf-query -c xfce4-panel -p "/plugins/plugin-$P1" -n -t string -s power-manager-plugin
xfconf-query -c xfce4-panel -p "/plugins/plugin-$P2" -n -t string -s pulseaudio-plugin

# 把完整数组写回去（含新 id）
SET=""
for i in $IDS; do
    case "$i" in ''|*[!0-9]*) continue;; esac
    SET="$SET -t int -s $i"
done
SET="$SET -t int -s $P1 -t int -s $P2"
# shellcheck disable=SC2086
xfconf-query -c xfce4-panel -p /panels/panel-1/plugin-ids -n $SET
echo "  done"

echo
echo "=== 6. 重启面板 ==="
xfce4-panel -r 2>/dev/null
sleep 5
pgrep -af xfce4-panel | head -2 || { echo "  PANEL DIED"; tail -20 /tmp/panel.log; exit 1; }

echo
echo "=== 7. 结果 ==="
xfconf-query -c xfce4-panel -p /panels/panel-1/plugin-ids 2>/dev/null | tr '\n' ' '
echo
for i in $P1 $P2; do
    echo "  plugin-$i = $(xfconf-query -c xfce4-panel -p /plugins/plugin-$i 2>/dev/null)"
done
echo
echo "=== panel log ==="
tail -8 /tmp/panel.log 2>/dev/null
