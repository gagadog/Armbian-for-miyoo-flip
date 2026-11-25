#!/bin/bash
set -e
cd "$HOME/miyoo-build/img"
IMG="Armbian_26.11.2_Anbernic-rg-ds_trixie_edge_7.3.5_minimal.img"
P1=p1.img
P2=p2.img
[ -f "$P1" ] || dd if="$IMG" of="$P1" bs=1M skip=16 count=1024 status=none
[ -f "$P2" ] || dd if="$IMG" of="$P2" bs=1M skip=1040 count=2188 status=none
echo "=== p1 ==="
file "$P1"
echo "=== p2 ==="
file "$P2"
echo
echo "=== tools ==="
for t in mdir mcopy mtype mkfs.vfat debugfs e2ls e2cp dump.ext4 python3 7z; do
    if command -v "$t" >/dev/null 2>&1; then echo "OK   $t"; else echo "MISS $t"; fi
done
