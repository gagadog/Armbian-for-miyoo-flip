#!/bin/bash
O="/mnt/d/wendang/默认项目/miyoo-flip-dtb/out"
for f in armbian usbhost joypad; do
    dtc -I dtb -O dts "$O/rk3566-miyoo-flip-$f-7.3.dtb" -o "/tmp/$f.dts" 2>/dev/null
    echo "=== $f ==="
    grep -n 'dr_mode' "/tmp/$f.dts"
    echo "  gpio-keys node: $(grep -c 'compatible = "gpio-keys"' "/tmp/$f.dts")"
    echo "  joypad node:    $(grep -c 'rocknix-singleadc-joypad' "/tmp/$f.dts")"
done
