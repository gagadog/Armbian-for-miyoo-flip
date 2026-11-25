#!/bin/sh
echo "=== joypad + serial dmesg (all) ==="
echo miyoo | sudo -S dmesg 2>/dev/null | grep -iE 'joypad|ttyS1|serial read|Miyoo' | tail -30
echo
echo "=== ttyS1 exists? ==="
ls -l /dev/ttyS1 2>&1
echo
echo "=== uart1 node state from DT ==="
echo miyoo | sudo -S cat /proc/device-tree/serial@fe650000/status 2>/dev/null; echo
echo miyoo | sudo -S ls /proc/device-tree/serial@fe650000/ 2>/dev/null
echo
echo "=== uart1 pinctrl ==="
echo miyoo | sudo -S cat /proc/device-tree/pinctrl/uart1/*/rockchip,pins 2>/dev/null | od -An -tu1 | head -3
echo miyoo | sudo -S ls /proc/device-tree/pinctrl/ 2>/dev/null | head -30
echo
echo "=== uart1 register dump (is anything clocking?) ==="
echo miyoo | sudo -S busybox devmem 0xfe650000 32 2>/dev/null || echo "(devmem unavailable)"
echo
echo "=== who holds ttyS1 ==="
echo miyoo | sudo -S fuser -v /dev/ttyS1 2>&1 | head -5
