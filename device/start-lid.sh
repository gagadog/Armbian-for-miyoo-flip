#!/bin/sh
echo "=== daemon-reload ==="
systemctl daemon-reload 2>&1 | head -2
echo "=== start lid service ==="
systemctl start miyoo-lid.service 2>&1 | head -3 || true
sleep 2
systemctl is-active miyoo-lid.service 2>&1 || true
pgrep -af miyoo-lid || echo "  not running"

echo
echo "=== restore a sane brightness ==="
echo 120 > /sys/class/backlight/backlight/brightness
cat /sys/class/backlight/backlight/brightness

echo
echo "=== logind re-read? (takes effect after restart of logind) ==="
systemctl show systemd-logind -p HandleLidSwitch 2>/dev/null || \
  grep -r HandleLidSwitch /etc/systemd/logind.conf.d/ 2>/dev/null
