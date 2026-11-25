#!/bin/sh
echo "=== driver: which tty does it open? ==="
grep -nE 'ttyS|/dev/tty|filp_open|kernel_read|kthread|miyoo_serial' /home/wang/miyoo-build/joypad/drv/rocknix-singleadc-joypad.c 2>/dev/null | head -20
echo "(source not on device, this section will be empty)"
echo
echo "=== kernel threads ==="
ps -e -o pid,comm | grep -iE 'miyoo|joypad' || echo "no named kthread"
echo
echo "=== uart1 hardware ==="
ls -l /dev/ttyS1 2>&1
cat /sys/class/tty/ttyS1/device/../modalias 2>/dev/null
echo
echo "=== dmesg: serial/joypad ==="
echo miyoo | sudo -S dmesg 2>/dev/null | grep -iE 'joypad|ttyS1|fe650000' | tail -20
echo
echo "=== sysfs calibration attrs (from patch 0003) ==="
for d in /sys/devices/platform/rocknix-singleadc-joypad; do
    ls -l "$d" 2>/dev/null | head -20
done
find /sys -name '*range*' -path '*joypad*' 2>/dev/null | head
find /sys -name '*calib*' -path '*joypad*' 2>/dev/null | head
