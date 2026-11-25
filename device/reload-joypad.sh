#!/bin/sh
echo "=== module state ==="
lsmod | grep -i joypad || echo "not loaded"
echo
echo "=== try load with explicit output ==="
rmmod rocknix_singleadc_joypad 2>&1 || true
modprobe rocknix-singleadc-joypad 2>&1 || echo "modprobe rc=$?"
echo
echo "=== dmesg tail 25 ==="
dmesg 2>/dev/null | tail -25
