#!/bin/bash
D="/mnt/d/wendang/默认项目/miyoo-flip-dtb/out/rk3566-miyoo-flip-armbian-7.3.dtb"
cp /home/wang/miyoo-build/src/linux-7.3.5/arch/arm64/boot/dts/rockchip/rk3566-miyoo-flip-armbian.dtb "$D"
dtc -I dtb -O dts "$D" -o /tmp/dec735.dts 2>/dev/null
echo "=== identity ==="
grep -nE 'model = |compatible = "miyoo|stdout-path' /tmp/dec735.dts | head
echo
echo "=== panel node ==="
awk '/panel@0 \{/,/^\t\t\t\};/' /tmp/dec735.dts | grep -vE 'panel_description|init' | head -20
echo
echo "=== gamepad ==="
grep -nE 'gpio-keys-polled|joypad|BTN_DPAD_UP|linux,code' /tmp/dec735.dts | head -6
echo "button count: $(grep -cE '^\s+sw[0-9]+ \{' /tmp/dec735.dts)"
echo
echo "=== storage / wifi / audio ==="
grep -nE 'mmc0 =|mmc1 =|regulator-name = "vcc_wifi|simple-audio-card|spk_amp' /tmp/dec735.dts | head
echo
echo "=== size ==="
ls -l "$D"
