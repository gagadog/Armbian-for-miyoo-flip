#!/bin/bash
D="/mnt/d/wendang/默认项目/miyoo-flip-dtb/device"
echo "=== asound.state: Playback Mux ==="
grep -n -A6 'Playback Mux' "$D/asound.state" | head -12
echo
echo "=== panel xml plugins ==="
grep -oE 'name="plugin-[0-9]+" type="string" value="[^"]+"' "$D/xfce4-panel.xml"
