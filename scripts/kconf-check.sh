#!/bin/bash
K=/home/wang/miyoo-build/src/linux-7.3.5
echo "=== .config ==="
grep -E '^CONFIG_MODULES=|^CONFIG_LOCALVERSION=' "$K/.config"
echo "=== /tmp/kconfig.keep ==="
grep -E '^CONFIG_MODULES=|^CONFIG_LOCALVERSION=' /tmp/kconfig.keep 2>/dev/null || echo "(no keep file)"
echo "=== generated auto.conf ==="
grep -E '^CONFIG_MODULES=' "$K/include/config/auto.conf" 2>/dev/null || echo "(none)"
