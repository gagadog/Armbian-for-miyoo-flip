#!/bin/sh
su - miyoo -c '
export DISPLAY=:0 XAUTHORITY=$HOME/.Xauthority
export DBUS_SESSION_BUS_ADDRESS=unix:path=/run/user/$(id -u)/bus
pkill -x xfce4-panel 2>/dev/null
sleep 2
: > $HOME/panel-final.log
setsid nohup xfce4-panel >> $HOME/panel-final.log 2>&1 &
sleep 8
if pgrep -x xfce4-panel >/dev/null; then
    echo "  panel ok pid $(pgrep -x xfce4-panel | head -1)"
else
    echo "  PANEL FAILED"
fi
echo "  plugins:"
for i in $(xfconf-query -c xfce4-panel -p /panels/panel-1/plugin-ids 2>/dev/null | grep -E "^[0-9]+$"); do
    echo "    $i = $(xfconf-query -c xfce4-panel -p /plugins/plugin-$i 2>/dev/null)"
done
echo "  log (filtered):"
grep -viE "session manager|SESSION_MANAGER" $HOME/panel-final.log 2>/dev/null | head -10
'
