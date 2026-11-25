#!/bin/sh
echo "=== gadget service ==="
systemctl is-active miyoo-usb-gadget.service
ls /dev/ttyGS* 2>/dev/null
systemctl --no-pager --no-legend list-units serial-getty
echo
echo "=== antimicrox autostart log ==="
ls -l /home/miyoo/antimicrox.log 2>/dev/null || echo "no log"
tail -25 /home/miyoo/antimicrox.log 2>/dev/null
echo
echo "=== antimicrox running? ==="
ps ax -o pid,user,args | grep -i antimicro | grep -v grep || echo "not running"
echo
echo "=== pad2key service (Armbian remap daemon) ==="
systemctl --no-pager -l status rgds-pad2key.service 2>/dev/null | head -14
echo
echo "=== input devices ==="
for d in /sys/class/input/event*; do
    n=$(cat "$d/device/name" 2>/dev/null)
    echo "$(basename $d)  $n"
done
echo
echo "=== xfce session / display ==="
ls /tmp/.X11-unix/ 2>/dev/null
who 2>/dev/null | head -5
