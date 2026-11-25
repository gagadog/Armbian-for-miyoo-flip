#!/bin/bash
K=/home/wang/miyoo-build/src/linux-7.3.5
sed -n '285,330p' "$K/include/drm/drm_panel.h"
echo "=== drm_of.h orientation ==="
grep -rn 'drm_of_get_panel_orientation' "$K/include/drm/"*.h
echo
echo "=== module: ctx alloc + panel struct ==="
grep -n 'devm_kzalloc\|struct drm_panel panel\|struct generic_panel \*ctx\|orientation' "/mnt/d/wendang/默认项目/miyoo-flip-dtb/module/panel-generic-dsi.c"
