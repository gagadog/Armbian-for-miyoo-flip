#!/bin/bash
K=/home/wang/miyoo-build/src/linux-7.3.5
echo "=== mainline rk3566/3568 boards using gpio-keys ==="
grep -rln 'compatible = "gpio-keys"' "$K/arch/arm64/boot/dts/rockchip/" | head -8
echo
echo "=== sample: which compatible is used where ==="
grep -rn 'compatible = "gpio-keys' "$K/arch/arm64/boot/dts/rockchip/" | head -12
echo
echo "=== MTD SPI NAND symbol name in 7.3.5 ==="
grep -rn 'config MTD_.*SPI_NAND\|Spi-nand\|spi-nand' "$K/drivers/mtd/nand/Kconfig" | head
echo "--- config check ---"
C=/home/wang/miyoo-build/src/linux-7.3.5/.config
grep -E 'MTD_NAND|SPI_NAND' "$C" | head -20
