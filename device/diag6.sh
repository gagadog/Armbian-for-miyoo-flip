#!/bin/sh
P=/home/miyoo/.config/xfce4/xfconf/xfce-perchannel-xml/xfce4-panel.xml
echo "=== panel config exists? ==="
ls -l "$P" 2>&1
echo
echo "=== plugins in panel ==="
grep -E 'plugin-[0-9]+" type="string"|systray|value="[a-z-]+"' "$P" 2>/dev/null | head -30
echo
echo "=== panel running plugins (live) ==="
DISPLAY=:0 XAUTHORITY=/home/miyoo/.Xauthority xfconf-query -c xfce4-panel -p /plugins -l 2>&1 | head -20
echo
echo "=== antimicrox tray/hidden state ==="
ps ax -o pid,args | grep -i 'antimicrox' | grep -v grep
echo
echo "=== desktop entries for antimicrox ==="
ls -l /usr/share/applications/ | grep -i antimicro
cat /usr/share/applications/antimicrox.desktop 2>/dev/null | grep -E '^Exec|^Name'
echo
echo "=== current autostart ==="
cat /home/miyoo/.config/autostart/antimicrox.desktop
