#!/bin/bash
K=/home/wang/miyoo-build/src/linux-7.3.5
echo "=== exports ==="
grep -rn 'EXPORT_SYMBOL.*drm_of_get_panel_orientation\|EXPORT_SYMBOL.*__devm_drm_panel_alloc\|EXPORT_SYMBOL.*drm_panel_add' "$K/drivers/gpu/drm/" | head
echo
echo "=== utsrelease ==="
cat "$K/include/generated/utsrelease.h" 2>/dev/null
cat "$K/include/config/kernel.release" 2>/dev/null
echo
echo "=== drm_of.h 40-60 ==="
sed -n '40,60p' "$K/include/drm/drm_of.h"
