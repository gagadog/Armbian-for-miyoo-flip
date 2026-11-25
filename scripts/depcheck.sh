#!/bin/bash
R=/mnt/miyoo-root/lib/modules/7.3.5-edge-rockchip64
CFG=/mnt/miyoo-boot/config-7.3.5-edge-rockchip64
echo "=== CONFIG_DRM ==="
grep -E '^CONFIG_DRM=|^CONFIG_DRM_KMS_HELPER|^CONFIG_DRM_MIPI_DSI' "$CFG"
echo
echo "=== modules.alias for the panel ==="
grep -i 'rocknix,generic-dsi' "$R/modules.alias" || echo "NO ALIAS"
echo
echo "=== is drm a module? ==="
ls "$R/kernel/drivers/gpu/drm/" | head -10
echo
echo "=== depmod -v (filtered) ==="
depmod -b /mnt/miyoo-root -v 7.3.5-edge-rockchip64 2>&1 | grep -i 'panel-generic' | head
echo "=== deps of a module that needs drm ==="
grep -m3 'drm_panel\|drm_kms_helper' "$R/modules.dep" | head -3
