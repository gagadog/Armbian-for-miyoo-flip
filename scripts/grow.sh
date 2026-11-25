#!/bin/bash
# Grow the rootfs partition so a desktop fits, then resize the filesystem.
set -e
. "$(dirname "$0")/env.sh"
NEWP2=10485760          # 5 GiB in 512-byte sectors
P2START=2129920

sync
umount /mnt/miyoo-boot 2>/dev/null || true
umount /mnt/miyoo-root 2>/dev/null || true
for l in $(losetup -j "$IMG" | cut -d: -f1); do losetup -d "$l"; done
sleep 1

CUR=$(stat -c %s "$IMG")
TARGET=$(( P2START * 512 + NEWP2 * 512 ))
echo "current image: $CUR bytes"
echo "target  image: $TARGET bytes"
if [ "$CUR" -lt "$TARGET" ]; then
    truncate -s "$TARGET" "$IMG"
fi
ls -l "$IMG"

echo "=== extend partition 2 ==="
echo ",+" | sfdisk -N 2 --force --no-reread "$IMG"
sfdisk -d "$IMG"

echo "=== resize filesystem ==="
LOOP=$(losetup -fP --show "$IMG")
losetup -c "$LOOP"
e2fsck -f -y "${LOOP}p2" | tail -3
resize2fs "${LOOP}p2"
losetup -d "$LOOP"
echo "=== done ==="
