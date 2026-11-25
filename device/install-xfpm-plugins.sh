#!/bin/sh
set -e
echo "=== install xfce4-power-manager-plugins ==="
dpkg -i /tmp/xpm-plugins.deb 2>&1 | grep -E 'Setting up|error|depends' | head -5
echo
echo "=== .so present? ==="
ls -l /usr/lib/aarch64-linux-gnu/xfce4/panel/plugins/libpowermanager.so 2>&1
ls /usr/share/xfce4/panel/plugins/ | grep -i power

echo
echo "=== restart panel (as miyoo) ==="
su - miyoo -c '
  export DISPLAY=:0 XAUTHORITY=$HOME/.Xauthority
  export DBUS_SESSION_BUS_ADDRESS=unix:path=/run/user/$(id -u)/bus
  pkill -x xfce4-panel 2>/dev/null
  sleep 2
  : > $HOME/panel-final.log
  setsid nohup xfce4-panel >> $HOME/panel-final.log 2>&1 &
  sleep 8
  pgrep -x xfce4-panel >/dev/null && echo "  panel ok pid $(pgrep -x xfce4-panel | head -1)" || echo "  PANEL FAILED"
  echo "  plugin list:"
  for i in $(xfconf-query -c xfce4-panel -p /panels/panel-1/plugin-ids 2>/dev/null | grep -E "^[0-9]+$"); do
      echo "    $i = $(xfconf-query -c xfce4-panel -p /plugins/plugin-$i 2>/dev/null)"
  done
  echo "  log:"
  grep -viE "session manager|SESSION_MANAGER" $HOME/panel-final.log 2>/dev/null | head -6
'
