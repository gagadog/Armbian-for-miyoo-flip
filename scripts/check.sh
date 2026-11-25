#!/bin/bash
K=$HOME/miyoo-build/src/linux-6.12.119
cd "$K" || exit 1
for f in \
  include/dt-bindings/suspend/rockchip-rk3568.h \
  include/dt-bindings/input/gpio-keys.h \
  include/dt-bindings/input/linux-event-codes.h \
  include/dt-bindings/soc/rockchip,vop2.h \
  include/dt-bindings/display/rockchip_vop.h \
  include/dt-bindings/leds/common.h \
  include/dt-bindings/display/media-bus-format.h ; do
  if [ -f "$f" ]; then echo "OK   $f"; else echo "MISS $f"; fi
done
echo "--- labels ---"
grep -nE 'scmi_clk:|cpu0_opp_table:|pmu_io_domains:|opp-408000000|dsi_dphy0:' \
  arch/arm64/boot/dts/rockchip/rk3566.dtsi arch/arm64/boot/dts/rockchip/rk3568.dtsi | head -30
echo "--- pmu_io_domains props ---"
sed -n '/pmu_io_domains:/,/};/p' arch/arm64/boot/dts/rockchip/rk3568.dtsi | head -30
