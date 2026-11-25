#!/bin/bash
F=/tmp/dec735.dts
echo "=== aliases ==="
awk '/aliases \{/,/^\t\};/' "$F" | head -20
echo
echo "=== uart nodes ==="
awk '/serial@fe6[0-9a-f]+ \{/,/^\t\};/' "$F" | grep -E 'serial@|status|pinctrl-0' | head -20
echo
echo "=== sdmmc0 / sdmmc1 / sfc ==="
for n in 'mmc@fe2b0000' 'mmc@fe2c0000' 'spi@fe300000'; do
  echo "-- $n"
  awk -v pat="$n" 'index($0,pat) && /\{/ {f=1} f {print} f && /^\t\};/ {f=0}' "$F" | grep -E 'compatible|status|bus-width|max-frequency' | head -6
done
echo
echo "=== backlight / pwm ==="
grep -nE 'pwm-backlight|pwms = |brightness-levels' "$F" | head -6
echo
echo "=== dsi + panel chain ==="
grep -nE 'dsi@fe060000|dsi_dphy|panel@0|status = "okay"' "$F" | sed -n '1,5p'
