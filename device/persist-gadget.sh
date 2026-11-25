#!/bin/sh
# Persist the composite gadget: install the fixed supervisor, drop the boot-time
# mask, and hand supervision over to systemd.
set -e

install -m 755 /tmp/miyoo-usb-gadget /usr/local/sbin/miyoo-usb-gadget

# remove the temporary kernel-cmdline mask (added when the gadget was broken)
sed -i 's/ systemd.mask=miyoo-usb-gadget\.service//' /boot/armbianEnv.txt
sed -i 's/systemd.mask=miyoo-usb-gadget\.service//' /boot/armbianEnv.txt

systemctl unmask miyoo-usb-gadget.service 2>/dev/null || true
# a mask coming from the kernel cmdline (systemd.mask=) lives in /run and is not
# removable with "systemctl unmask"; drop it by hand
rm -f /run/systemd/system/miyoo-usb-gadget.service
systemctl daemon-reload

# stop the ad-hoc supervisor started from the serial console
pkill -f 'miyoo-usb-gadget loop' 2>/dev/null || true
sleep 1

systemctl daemon-reload
systemctl enable miyoo-usb-gadget.service 2>/dev/null || true
systemctl restart miyoo-usb-gadget.service
sleep 4

echo "== boot env =="
grep -E '^(extraargs|fdtfile)' /boot/armbianEnv.txt
echo "== service =="
systemctl is-active miyoo-usb-gadget.service
echo "== ttys =="
ls /dev/ttyGS* 2>/dev/null || echo none
echo "== getty =="
systemctl list-units 'serial-getty@*' --no-legend --no-pager | sed 's/^/  /'
echo "== net =="
ip -o -4 addr show usb0 2>/dev/null | sed 's/^/  /' || echo "no usb0"
echo "== last log =="
tail -6 /var/log/miyoo-gadget.log 2>/dev/null | sed 's/^/  /'
