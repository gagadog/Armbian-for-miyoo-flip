#!/bin/bash
K=/home/wang/miyoo-build/src/linux-7.3.5
echo "=== drm_panel.h: init-ish declarations ==="
grep -nE '^[a-zA-Z].*drm_panel|^struct drm_panel \*|init' "$K/include/drm/drm_panel.h" | sed -n '1,60p'
echo
echo "=== st7701 probe tail ==="
sed -n '1285,1330p' "$K/drivers/gpu/drm/panel/panel-sitronix-st7701.c"
