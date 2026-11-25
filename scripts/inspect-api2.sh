#!/bin/bash
K=/home/wang/miyoo-build/src/linux-7.3.5
echo "=== drm_panel_init / drm_panel_add in 7.3.5 ==="
grep -rn 'drm_panel_init\|drm_panel_add\|drm_panel_remove\|drm_panel_of_backlight' "$K/include/drm/"*.h | head -20
echo
echo "=== of_drm_get_panel_orientation anywhere ==="
grep -rn 'of_drm_get_panel_orientation' "$K/include" "$K/drivers/gpu/drm/drm_of.c" 2>/dev/null | head
echo
echo "=== a sample mainline DSI panel driver probe, 7.3.5 ==="
sed -n '1,40p' "$K/drivers/gpu/drm/panel/panel-sitronix-st7701.c" | head -5
grep -n 'drm_panel_init\|panel_orientation\|drm_panel_add' "$K/drivers/gpu/drm/panel/panel-sitronix-st7701.c" | head
echo
echo "=== how st7701 gets orientation ==="
grep -rn 'orientation' "$K/drivers/gpu/drm/panel/panel-sitronix-st7701.c" | head
