#!/bin/bash
C=/home/wang/miyoo-build/src/linux-7.3.5/.config
echo "=== amp driver in kernel config ==="
for k in SND_SIMPLE_AMP SND_SIMPLE_AMPLIFIER SND_SOC_SIMPLE_AMPLIFIER SND_SIMPLE_CARD SND_SOC_RK817; do
  line=$(grep -E "^CONFIG_${k}=" "$C"); [ -z "$line" ] && line="--- not set ---"
  printf '  %-32s %s\n' "$k" "$line"
done
echo
echo "=== DTB: amp node ==="
dtc -I dtb -O dts "/mnt/d/wendang/默认项目/miyoo-flip-dtb/out/rk3566-miyoo-flip-joypad-7.3.dtb" -o /tmp/a.dts 2>/dev/null
awk '/audio-amplifier|simple-audio-amplifier/,/};/' /tmp/a.dts | head -20
echo
echo "=== DTB: sound node aux-devs ==="
grep -n -A8 'rk817-sound\|simple-audio-card,aux-devs\|sound-name-prefix' /tmp/a.dts | head -20
