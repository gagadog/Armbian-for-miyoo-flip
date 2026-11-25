#!/bin/sh
export DISPLAY=:0
export XAUTHORITY="$HOME/.Xauthority"
XP="xfconf-query -c xfce4-panel"

echo "=== plugin types (correct path) ==="
for i in 1 2 3 4 5 6 7 8 9 10 11 12; do
    t=$($XP -p "/plugins/plugin-$i" 2>/dev/null | head -1)
    echo "  plugin-$i = $t"
done

echo
echo "=== audio: switch Playback Mux HP -> SPK ==="
amixer -c 1 sset 'Playback Mux' SPK 2>&1 | tail -2
amixer -c 1 sget 'Playback Mux' 2>&1 | tail -3

echo
echo "=== play 3s tone on the speaker ==="
timeout 8 aplay -D plughw:1,0 /tmp/tone.wav 2>&1 | tail -2
echo "  rc=$?"

echo
echo "=== amp gpio after ==="
grep -E 'gpio-18.*enable' /sys/kernel/debug/gpio 2>/dev/null | sed 's/^/  /'
