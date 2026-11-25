#!/bin/sh
P=/home/miyoo/.config/xfce4/xfconf/xfce-perchannel-xml/xfce4-panel.xml
echo "=== panel xml: plugin declarations ==="
grep -nE 'plugin-[0-9]+" type="string"|name="plugin-ids"|<value type="int"' "$P" | head -60
echo
echo "=== power manager autostart ==="
ls /etc/xdg/autostart/ 2>/dev/null | grep -iE 'power|pulse|vol' 
ls /home/miyoo/.config/autostart/ | sed 's/^/  /'
echo
echo "=== is xfce4-power-manager installed? ==="
which xfce4-power-manager xfce4-panel pulseaudio pactl wpctl 2>&1
echo
echo "=== pulseaudio plugin installed? ==="
ls /usr/lib/*/xfce4/panel/plugins/ 2>/dev/null | head -20
