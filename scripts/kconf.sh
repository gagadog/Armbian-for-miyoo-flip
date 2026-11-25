#!/bin/bash
set -e
CFG=/mnt/miyoo-boot/config-7.3.5-edge-rockchip64
echo "=== module related config ==="
grep -E '^CONFIG_(MODVERSIONS|MODULE_SIG|MODULE_SIG_FORCE|MODULE_COMPRESS|LOCALVERSION|MODULES=|MODULE_UNLOAD)' "$CFG"
echo
echo "=== in-tree rtl8733 / 8733 ==="
grep -iE '8733|RTL8XXXU|RTW88|RTW89' "$CFG" | head -20
echo
echo "=== panel / drm ==="
grep -iE '^CONFIG_DRM_PANEL' "$CFG" | grep -c '=m\|=y'
grep -iE 'FT8006|PANEL_SIMPLE|DRM_MIPI_DSI|DRM_PANEL_SIMPLE' "$CFG"
echo
echo "=== rk3566 bits ==="
grep -iE '^CONFIG_(ARCH_ROCKCHIP|ROCKCHIP_IODOMAIN|PHY_ROCKCHIP|DRM_ROCKCHIP|ROCKCHIP_SARADC|GPIO_KEYS|KEYBOARD_GPIO)' "$CFG"
echo
echo "=== /lib/modules ==="
ls -l /mnt/miyoo-root/lib/modules/
ls /mnt/miyoo-root/lib/modules/*/ | head -20
echo
echo "=== modules.dep size ==="
ls -l /mnt/miyoo-root/lib/modules/*/modules.dep 2>/dev/null | head
echo
echo "=== rootfs modules-load / etc ==="
ls -l /mnt/miyoo-root/etc/modules-load.d/ 2>/dev/null
cat /mnt/miyoo-root/etc/modules 2>/dev/null | head
