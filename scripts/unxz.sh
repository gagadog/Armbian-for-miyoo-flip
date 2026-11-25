#!/bin/bash
set -e
cd "$HOME/miyoo-build/img"
IMG="Armbian_26.11.2_Anbernic-rg-ds_trixie_edge_7.3.5_minimal.img"
if [ ! -f "$IMG" ]; then
    xz -dc "Armbian_26.11.2_Anbernic-rg-ds_trixie_edge_7.3.5_minimal.img.xz" > "$IMG"
fi
ls -l "$IMG"
echo "=== partition table ==="
sfdisk -d "$IMG" 2>/dev/null || fdisk -l "$IMG"
echo "=== file type ==="
file "$IMG"
