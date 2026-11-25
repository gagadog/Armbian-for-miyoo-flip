#!/bin/sh
echo "=== amixer controls on card 1 (raw) ==="
amixer -c 1 scontrols 2>&1 | head -20
echo
echo "=== DAPM widget names containing Speaker/Amp/SPK ==="
amixer -c 1 contents 2>/dev/null | grep -iE 'name=.*(speaker|amp|spk)' | head -10 || echo "  none"

echo
echo "=== gpio before ==="
grep -E 'gpiochip4|gpio-18.*enable' /sys/kernel/debug/gpio 2>/dev/null | head -3

echo
echo "=== play 3s via ALSA, sample gpio during playback ==="
audio_play_test() {
    aplay -D plughw:1,0 /tmp/tone.wav >/dev/null 2>&1 &
    AP=$!
    sleep 0.8
    echo "  during:"
    grep -E 'gpio-18.*(enable|amp)' /sys/kernel/debug/gpio 2>/dev/null | head -2 | sed 's/^/    /'
    wait $AP
    sleep 0.3
    echo "  after:"
    grep -E 'gpio-18.*(enable|amp)' /sys/kernel/debug/gpio 2>/dev/null | head -2 | sed 's/^/    /'
}
audio_play_test

echo
echo "=== try speaker-test on plughw:1,0 (2s) ==="
timeout 6 speaker-test -D plughw:1,0 -c 2 -t sine -f 440 -l 1 2>&1 | tail -5

echo
echo "=== dmesg audio ==="
dmesg 2>/dev/null | grep -iE 'rk817|simple-card|amplifier|dapm' | tail -10
