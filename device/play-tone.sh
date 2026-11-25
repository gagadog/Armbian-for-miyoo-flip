#!/bin/sh
echo "=== amp / sound card dmesg ==="
dmesg 2>/dev/null | grep -iE 'simple-audio|amplifier|spk|rk817.*(sound|codec)' | tail -8 || true
echo
echo "=== generate test tone ==="
python3 - <<'PY'
import math, struct, wave
rate = 44100
dur = 2.5
frames = bytearray()
for i in range(int(rate * dur)):
    t = i / rate
    fade = min(1.0, t / 0.05, (dur - t) / 0.05)
    # simple two-tone chime
    v = 0.45 * math.sin(2 * math.pi * 440 * t) + 0.30 * math.sin(2 * math.pi * 880 * t)
    s = int(max(-1.0, min(1.0, v * fade)) * 32000)
    frames += struct.pack('<hh', s, s)
w = wave.open('/tmp/tone.wav', 'wb')
w.setnchannels(2); w.setsampwidth(2); w.setframerate(rate)
w.writeframes(bytes(frames)); w.close()
print("  /tmp/tone.wav written")
PY
ls -l /tmp/tone.wav

echo
echo "=== set volume 80% ==="
wpctl set-volume @DEFAULT_AUDIO_SINK@ 0.8 2>&1 | head -2
wpctl status 2>/dev/null | grep -A2 'Sinks:' | head -4

echo
echo "=== play via pipewire (pw-play) ==="
timeout 8 pw-play /tmp/tone.wav 2>&1 | head -5
echo "  rc=$?"

echo
echo "=== play via ALSA direct (aplay hw:1,0) ==="
timeout 8 aplay -D plughw:1,0 /tmp/tone.wav 2>&1 | head -5
echo "  rc=$?"
