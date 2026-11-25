#!/bin/bash
set -e
. "$(dirname "$0")/env.sh"
M="$ROOT/module"
cd "$M"
rm -f *.o *.ko *.mod *.mod.c *.cmd modules.order Module.symvers .*.cmd 2>/dev/null || true
make -C "$K" ARCH=arm64 CROSS_COMPILE="$TC" M="$M" KBUILD_MODPOST_WARN=1 modules 2>&1 | tail -20
echo "=== result ==="
ls -l panel-generic-dsi.ko 2>/dev/null || { echo NO_KO; exit 1; }
echo "=== vermagic ==="
python3 - "$M/panel-generic-dsi.ko" <<'EOF'
import struct,sys
p=sys.argv[1]
d=open(p,'rb').read()
i=d.find(b'vermagic=')
print(d[i:i+120].split(b'\x00')[0].decode())
EOF
