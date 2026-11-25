#!/bin/bash
O="/mnt/d/wendang/默认项目/miyoo-flip-dtb/out"
for f in "$O"/rk3566-miyoo-flip-armbian-7.3.dtb \
         "$O"/rk3566-miyoo-flip-usbhost-7.3.dtb \
         "$O"/rk3566-miyoo-flip-joypad-7.3.dtb; do
    [ -f "$f" ] || { echo "missing $f"; continue; }
    dtc -I dtb -O dts "$f" -o /tmp/v.dts 2>/dev/null
    mode=$(awk '/usb@fcc00000 \{/{f=1} f&&/dr_mode/{print $3; exit}' /tmp/v.dts)
    pad=gpio-keys
    grep -q rocknix-singleadc-joypad /tmp/v.dts && pad=joypad
    printf '  %-34s %-12s %-10s %s bytes\n' "$(basename "$f")" "$mode" "$pad" "$(stat -c %s "$f")"
done
echo
echo "=== joypad node sanity ==="
dtc -I dtb -O dts "$O/rk3566-miyoo-flip-joypad-7.3.dtb" -o /tmp/j.dts 2>/dev/null
grep -cE '^\s+sw[0-9]+ \{' /tmp/j.dts
grep -E 'compatible = "rocknix|miyoo-deadzone|poll-interval' /tmp/j.dts | head -5
