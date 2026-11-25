#!/bin/sh
echo "=== sound cards ==="
cat /proc/asound/cards 2>/dev/null
echo
echo "=== players available ==="
for b in aplay speaker-test pw-play paplay ffplay mpv; do
    printf '  %-12s %s\n' "$b" "$(command -v $b || echo -)"
done
echo
echo "=== pipewire / wireplumber ==="
pgrep -a pipewire | head -3
pgrep -a wireplumber | head -2
echo
echo "=== sinks (wpctl) ==="
wpctl status 2>/dev/null | sed -n '/Audio/,/Video/p' | head -20 || echo "  wpctl unavailable"
echo
echo "=== mixer controls (card1 = rk817) ==="
amixer -c 1 scontrols 2>/dev/null | head -15 || echo "  amixer unavailable"
echo
echo "=== amp gpio ==="
gpioinfo 2>/dev/null | grep -i 'PC2\|amp' | head -5 || echo "  gpioinfo unavailable"
