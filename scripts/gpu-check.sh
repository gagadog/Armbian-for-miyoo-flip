#!/bin/bash
C=/home/wang/miyoo-build/src/linux-7.3.5/.config
echo "=== GPU / DRM in the Armbian kernel ==="
for k in DRM_PANFROST DRM_LIMA DRM_MALI MALI_BIFROST DRM_ROCKCHIP \
         DRM_SCHED DRM_GEM_SHMEM_HELPER; do
  line=$(grep -E "^CONFIG_${k}=" "$C"); [ -z "$line" ] && line="--- not set ---"
  printf '  %-28s %s\n' "$k" "$line"
done
echo
echo "=== image rootfs: mesa / vulkan ==="
R=/mnt/miyoo-root
for p in /usr/lib/aarch64-linux-gnu/dri/panfrost_dri.so \
         /usr/lib/aarch64-linux-gnu/libvulkan.so.1 \
         /usr/lib/aarch64-linux-gnu/libvulkan_panfrost.so \
         /usr/share/vulkan/icd.d; do
  if [ -e "$R$p" ]; then echo "  OK   $p"; else echo "  --   $p"; fi
done
echo
echo "  dri drivers present:"
ls "$R/usr/lib/aarch64-linux-gnu/dri/" 2>/dev/null | head -20
echo "  vulkan icd:"
ls "$R/usr/share/vulkan/icd.d/" 2>/dev/null || echo "   (none)"
echo
echo "=== installed packages of interest ==="
grep -E '^Package: (mesa-vulkan-drivers|libgl1-mesa-dri|mesa-utils|vulkan-tools|libvulkan1|antimicrox|libsdl2)' \
     "$R/var/lib/dpkg/status" -A1 | grep -E 'Package|Version' | paste - - | head -12
