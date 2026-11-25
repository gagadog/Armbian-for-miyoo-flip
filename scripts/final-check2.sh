#!/bin/bash
D="/mnt/d/wendang/默认项目/miyoo-flip-dtb/image"
cd "$D" || exit 1
echo "=== files ==="
ls -l
echo
echo "=== remove superseded minimal build ==="
rm -f Armbian-MiyooFlip_26.11.2_trixie_edge_7.3.5_minimal.img.xz \
      Armbian-MiyooFlip_26.11.2_trixie_edge_7.3.5_minimal.img.xz.sha256 \
      Armbian-MiyooFlip_26.11.2_trixie_edge_7.3.5_minimal.img.xz.part
ls -l
echo
echo "=== xz integrity ==="
xz -t Armbian-MiyooFlip_26.11.2_trixie_edge_7.3.5_xfce.img.xz && echo "xz OK"
echo
echo "=== sha256 ==="
sha256sum Armbian-MiyooFlip_26.11.2_trixie_edge_7.3.5_xfce.img.xz
