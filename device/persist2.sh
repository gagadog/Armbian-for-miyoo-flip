#!/bin/sh
# Enable the gadget supervisor without systemctl (polkit in a non-tty ssh
# session refuses), then reboot so the runtime mask from the old kernel cmdline
# is gone for good.
set -e

ln -sf /etc/systemd/system/miyoo-usb-gadget.service \
       /etc/systemd/system/multi-user.target.wants/miyoo-usb-gadget.service

echo "== enable symlink =="
ls -l /etc/systemd/system/multi-user.target.wants/miyoo-usb-gadget.service

echo "== boot env =="
grep -E '^(extraargs|fdtfile)' /boot/armbianEnv.txt

echo "== supervisor script =="
ls -l /usr/local/sbin/miyoo-usb-gadget
head -3 /usr/local/sbin/miyoo-usb-gadget

echo "== rebooting =="
sync
reboot
