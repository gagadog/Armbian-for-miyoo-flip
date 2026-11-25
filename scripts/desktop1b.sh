#!/bin/bash
# Stage 1b: install the desktop stack (mounts prepared by dns-fix.sh).
set -e
R=/mnt/miyoo-root
for d in proc sys dev dev/pts; do
    mountpoint -q "$R/$d" || mount --bind "/$d" "$R/$d"
done
mountpoint -q "$R/etc/resolv.conf" || { rm -f "$R/etc/resolv.conf"; touch "$R/etc/resolv.conf"; mount --bind /etc/resolv.conf "$R/etc/resolv.conf"; }

echo "=== apt update ==="
chroot "$R" /usr/bin/env DEBIAN_FRONTEND=noninteractive apt-get update 2>&1 | tail -6

echo
echo "=== desktop core ==="
chroot "$R" /usr/bin/env DEBIAN_FRONTEND=noninteractive \
    apt-get install -y --no-install-recommends \
      xfce4 xfce4-terminal lightdm lightdm-gtk-greeter \
      xserver-xorg xserver-xorg-input-libinput libgl1-mesa-dri \
      dbus-x11 x11-xserver-utils fonts-dejavu-core sudo network-manager \
    2>&1 | tail -8
echo "rc=$?"

echo
echo "=== antimicrox + onboard ==="
chroot "$R" /usr/bin/env DEBIAN_FRONTEND=noninteractive \
    apt-get install -y --no-install-recommends antimicrox onboard 2>&1 | tail -6 || echo "WARN antimicrox/onboard"

echo
echo "=== audio ==="
chroot "$R" /usr/bin/env DEBIAN_FRONTEND=noninteractive \
    apt-get install -y --no-install-recommends \
      pipewire pipewire-pulse wireplumber xfce4-pulseaudio-plugin 2>&1 | tail -6 || echo "WARN audio"

echo
echo "=== result ==="
chroot "$R" /usr/bin/env bash -c 'ls /usr/share/xsessions/ 2>&1; for b in startxfce4 lightdm antimicrox onboard xset; do printf "%-14s %s\n" "$b" "$(command -v $b || echo MISSING)"; done'
df -h "$R"
echo STAGE1B_DONE
