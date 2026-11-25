#!/bin/bash
# Post-fix + verify + pack v3.
#  * give the RNDIS function explicit MACs and add MS OS descriptors so Windows
#    binds its RNDIS driver without manual help
#  * verify every piece we added
#  * repack
set -e
set -o pipefail
IMG=/home/wang/miyoo-build/img/Armbian_26.11.2_Anbernic-rg-ds_trixie_edge_7.3.5_minimal.img
DST="/mnt/d/wendang/默认项目/miyoo-flip-dtb/image"
NAME="Armbian-MiyooFlip_26.11.2_trixie_edge_7.3.5_xfce_v3.img.xz"
R=/mnt/miyoo-root
L=$(losetup -j "$IMG" | cut -d: -f1 | head -1)
[ -z "$L" ] && L=$(losetup -fP --show "$IMG")
mkdir -p "$R"; mountpoint -q "$R" || mount "${L}p2" "$R"

G="$R/usr/local/sbin/miyoo-usb-gadget"
echo "=== patch gadget script ==="
if ! grep -q 'dev_addr' "$G"; then
python3 - "$G" <<'PY'
import sys
p = sys.argv[1]
s = open(p).read()
old = '''    mkdir -p "$G/functions/rndis.usb0"
    ln -sf "$G/functions/rndis.usb0" "$G/configs/c.1/" 2>/dev/null || true
fi'''
new = '''    mkdir -p "$G/functions/rndis.usb0"
    echo "02:00:00:00:00:02" > "$G/functions/rndis.usb0/dev_addr"  || true
    echo "02:00:00:00:00:01" > "$G/functions/rndis.usb0/host_addr" || true
    ln -sf "$G/functions/rndis.usb0" "$G/configs/c.1/" 2>/dev/null || true

    # Microsoft OS descriptors: lets Windows bind the RNDIS driver by itself
    mkdir -p "$G/os_desc/interface.rndis"
    echo 1        > "$G/os_desc/use"       || true
    echo 0xcd     > "$G/os_desc/b_vendor_code" || true
    echo MSFT100  > "$G/os_desc/qw_sign"   || true
    ln -sf "$G/configs/c.1" "$G/os_desc" 2>/dev/null || true
fi'''
assert old in s, "anchor not found"
open(p, "w").write(s.replace(old, new))
print("patched")
PY
fi
grep -n 'dev_addr\|os_desc' "$G" | head

echo
echo "================ VERIFY ================"
echo "--- core ---"
grep 'fdtfile' "$R/boot/armbianEnv.txt" 2>/dev/null || true
ls -l /mnt/miyoo-boot/dtb/rockchip/rk3566-miyoo-flip.dtb 2>/dev/null || true
mountpoint -q /mnt/miyoo-boot || mount "${L}p1" /mnt/miyoo-boot
ls -l /mnt/miyoo-boot/dtb/rockchip/rk3566-miyoo-flip.dtb
grep 'fdtfile' /mnt/miyoo-boot/armbianEnv.txt

echo "--- tools ---"
for b in brightnessctl vulkaninfo glxinfo dnsmasq evtest lsusb strace; do
    printf '  %-14s %s\n' "$b" "$(ls "$R/usr/bin/$b" "$R/usr/sbin/$b" "$R/bin/$b" 2>/dev/null | head -1 || echo MISSING)"
done
echo "--- vulkan ICD ---"
ls "$R/usr/share/vulkan/icd.d/" 2>/dev/null || echo "  none"

echo "--- services enabled ---"
ls "$R/etc/systemd/system/multi-user.target.wants/" | grep -E 'ssh|lightdm|dnsmasq|gadget|NetworkManager' || true

echo "--- ssh keys ---"
ls -l "$R/home/miyoo/.ssh/" "$R/root/.ssh/" 2>/dev/null

echo "--- autostart ---"
cat "$R/home/miyoo/.config/autostart/antimicrox.desktop"
ls -l "$R/home/miyoo/Desktop/"

echo "--- brightness/udev ---"
cat "$R/etc/udev/rules.d/90-backlight-video.rules"
ls "$R/sys/class/backlight" 2>/dev/null || true

df -h "$R"
sync
umount /mnt/miyoo-boot 2>/dev/null || true
umount "$R"
losetup -d "$L"

echo "================ PACK ================"
mkdir -p "$DST"
xz -T0 -6 -c "$IMG" > "$DST/$NAME.part"
mv "$DST/$NAME.part" "$DST/$NAME"
ls -l "$DST/$NAME"
sha256sum "$DST/$NAME" | tee "$DST/$NAME.sha256"
echo V3_PACK_DONE
