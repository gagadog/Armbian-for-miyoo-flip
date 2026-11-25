#!/bin/sh
echo "=== service state ==="
systemctl is-enabled miyoo-padmouse.service 2>&1
systemctl restart miyoo-padmouse.service 2>&1
sleep 3
systemctl is-active miyoo-padmouse.service
echo
echo "=== it should have picked the real device ==="
journalctl -u miyoo-padmouse --no-pager -n 8 2>/dev/null | tail -8
echo
echo "=== input devices ==="
for d in /sys/class/input/event*; do echo "  $(basename $d)  $(cat $d/device/name 2>/dev/null)"; done
echo
echo "=== antimicrox autostart removed? ==="
ls /home/miyoo/.config/autostart/ 2>/dev/null
echo
echo "=== rgds-pad2key ==="
systemctl is-enabled rgds-pad2key.service 2>&1 || true
systemctl is-active rgds-pad2key.service 2>&1 || true
