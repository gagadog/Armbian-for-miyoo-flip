#!/bin/sh
set -e
echo "=== 1. install nm-applet ==="
mkdir -p /tmp/nma
# debs were scp'd to /tmp/nma
dpkg -i /tmp/nma/*.deb 2>&1 | grep -E 'Setting up|error|depends|Unpacking' | head -20
echo
echo "--- installed? ---"
dpkg -l network-manager-applet nm-connection-editor 2>/dev/null | grep '^ii' | awk '{print "  "$2" "$3}'
command -v nm-applet && echo "  nm-applet ok"
ls /etc/xdg/autostart/ | grep -i nm-applet | sed 's/^/  autostart: /'

echo
echo "=== 2. start nm-applet in the session ==="
pkill -f nm-applet 2>/dev/null || true
sleep 1
su - miyoo -c 'DISPLAY=:0 XAUTHORITY=$HOME/.Xauthority setsid nohup nm-applet > /tmp/nm-applet.log 2>&1 &'
sleep 4
pgrep -af nm-applet || echo "  not running"

echo
echo "=== 3. persist mixer state (Playback Mux = SPK) ==="
amixer -c 1 sget 'Playback Mux' 2>&1 | tail -2
alsactl store 2>&1 | head -3
ls -l /var/lib/alsa/asound.state 2>/dev/null

echo
echo "=== 4. panel plugins in xml ==="
P=/home/miyoo/.config/xfce4/xfconf/xfce-perchannel-xml/xfce4-panel.xml
grep -oE 'name="plugin-[0-9]+" type="string" value="[^"]+"' "$P" | head -20
