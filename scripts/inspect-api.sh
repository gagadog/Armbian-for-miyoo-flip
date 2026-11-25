#!/bin/bash
K=/home/wang/miyoo-build/src/linux-7.3.5
echo "=== .config LOCALVERSION ==="
grep -n 'LOCALVERSION' "$K/.config" | head
echo
echo "=== drm_panel_init signature ==="
grep -n -A12 'void drm_panel_init' "$K/include/drm/drm_panel.h"
echo
echo "=== of_drm_get_panel_orientation ==="
grep -rn 'of_drm_get_panel_orientation\|drm_connector_set_panel_orientation' "$K/include/drm/" | head
echo
echo "=== source around 600-650 ==="
sed -n '595,650p' "/mnt/d/wendang/默认项目/miyoo-flip-dtb/module/panel-generic-dsi.c"
echo
echo "=== includes of the module ==="
sed -n '1,40p' "/mnt/d/wendang/默认项目/miyoo-flip-dtb/module/panel-generic-dsi.c"
