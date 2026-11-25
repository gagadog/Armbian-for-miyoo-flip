#!/bin/bash
R=/mnt/miyoo-root/lib/modules/7.3.5-edge-rockchip64
echo "=== top level ==="
ls "$R"
echo "=== sample modules ==="
find "$R" -name '*.ko*' | head -5
echo "count: $(find "$R" -name '*.ko*' | wc -l)"
echo "=== drm ==="
find "$R" -name 'drm*.ko*' | head -5
echo "=== vermagic of a sample ==="
f=$(find "$R" -name '*.ko' | head -1)
echo "file: $f"
python3 -c "
import sys
d=open('$f','rb').read()
i=d.find(b'vermagic=')
print(d[i:i+120].split(b'\x00')[0].decode())
"
