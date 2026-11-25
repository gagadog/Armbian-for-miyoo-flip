#!/bin/sh
echo "=== amp module loaded? ==="
lsmod | grep -i simple_amp || echo "  not loaded"
lsmod | grep -E 'snd_soc_rk817|snd_soc_simple_card' | head -3

echo
echo "=== DAPM: Speaker Amp widgets ==="
amixer -c 1 contents 2>/dev/null | grep -iE 'Speaker|Amp' | head -12 || echo "  no amp controls"

echo
echo "=== gpio4 pin 18 (RK_PC2) state ==="
if [ -r /sys/kernel/debug/gpio ]; then
    grep -E 'gpio-?18|gpio4' /sys/kernel/debug/gpio | head -6
else
    mount -t debugfs none /sys/kernel/debug 2>/dev/null
    grep -E 'gpio-?18|gpio4' /sys/kernel/debug/gpio 2>/dev/null | head -6 || echo "  debugfs unavailable"
fi

echo
echo "=== force volume high on the rk817 sink (id 54) ==="
wpctl set-volume 54 0.95 2>&1 | head -2
wpctl status 2>/dev/null | grep -A3 'Sinks:' | head -5

echo
echo "=== play again via pipewire ==="
timeout 10 pw-play --volume 0.95 /tmp/tone.wav 2>&1 | head -5
echo "  rc=$?"

echo
echo "=== ALSA direct, card1 ==="
timeout 10 aplay -D hw:1,0 /tmp/tone.wav 2>&1 | head -6
echo "  rc=$?"
