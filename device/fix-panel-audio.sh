#!/bin/sh
export DISPLAY=:0
export XAUTHORITY="$HOME/.Xauthority"
XP="xfconf-query -c xfce4-panel"

echo "=== restore full plugin-ids array (1..10 + 11 power + 12 pulse) ==="
$XP -p /panels/panel-1/plugin-ids -n \
    -t int -s 1  -t int -s 2  -t int -s 3  -t int -s 4  -t int -s 5 \
    -t int -s 6  -t int -s 7  -t int -s 8  -t int -s 9  -t int -s 10 \
    -t int -s 11 -t int -s 12
echo "  done"

echo
echo "=== plugin types ==="
for i in 1 2 3 4 5 6 7 8 9 10 11 12; do
    t=$($XP -p "/plugins/plugin-$i/plugin" 2>/dev/null | head -1)
    echo "  plugin-$i = $t"
done

echo
echo "=== restart panel ==="
xfce4-panel -r 2>/dev/null
sleep 4
pgrep -c xfce4-panel | sed 's/^/  panel procs: /'

echo
echo "=== audio: Master level ==="
amixer -c 1 sget Master 2>&1 | head -6
echo "--- set 100% unmuted ---"
amixer -c 1 sset Master 100% unmute 2>&1 | tail -3
amixer -c 1 sget Master 2>&1 | head -6

echo
echo "=== Playback Mux options ==="
amixer -c 1 sget 'Playback Mux' 2>&1 | head -10

echo
echo "=== play tone (5s) ==="
timeout 8 aplay -D plughw:1,0 /tmp/tone.wav 2>&1 | tail -2
echo "  rc=$?"
