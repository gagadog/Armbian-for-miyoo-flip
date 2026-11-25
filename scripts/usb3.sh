#!/bin/bash
K=/home/wang/miyoo-build/src/linux-7.3.5
echo "=== rk808 regulator: OTG_SWITCH support ==="
grep -n 'OTG_SWITCH\|otg_switch' "$K/drivers/regulator/rk808-regulator.c" | head -20
echo
echo "=== rk817 of_match / regulator descs mentioning switch ==="
grep -n 'switch' "$K/drivers/regulator/rk808-regulator.c" | head -20
echo
echo "=== dwc3 vbus regulator ==="
grep -rn '"vbus"' "$K/drivers/usb/dwc3/core.c" | head
grep -rn 'vbus_reg\|dwc->vbus' "$K/drivers/usb/dwc3/core.c" | head -10
echo
echo "=== dwc3 rockchip glue role switch ==="
grep -rn 'otg_switch\|vbus-supply\|usb-role-switch' "$K/drivers/usb/dwc3/dwc3-rockchip.c" 2>/dev/null | head
ls "$K/drivers/usb/dwc3/" | head -20
