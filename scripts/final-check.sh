#!/bin/bash
cd "/mnt/d/wendang/默认项目/miyoo-flip-dtb/image" || exit 1
F="Armbian-MiyooFlip_26.11.2_trixie_edge_7.3.5_minimal.img.xz"
echo "=== size ==="
ls -l "$F"
du -h "$F"
echo "=== xz integrity ==="
xz -t "$F" && echo "xz OK"
echo "=== sha256 ==="
sha256sum "$F"
echo "=== partition table of decompressed image ==="
xz -dc "$F" | head -c 1048576 > /tmp/head.img
sfdisk -d /tmp/head.img 2>/dev/null | head -6
