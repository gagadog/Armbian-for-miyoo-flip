#!/bin/sh
REL=7.3.5-edge-rockchip64
echo "=== installed module on disk ==="
ls -l /lib/modules/$REL/extra/rocknix-singleadc-joypad.ko
python3 -c "
d=open('/lib/modules/$REL/extra/rocknix-singleadc-joypad.ko','rb').read()
i=d.find(b'vermagic=')
print('vermagic:', d[i:i+120].split(b'\x00')[0].decode())
"
echo "=== autoload configured? ==="
cat /etc/modules-load.d/rocknix-joypad.conf
echo "=== boot dtb ==="
grep fdtfile /boot/armbianEnv.txt
echo "=== rebooting ==="
sync
reboot
