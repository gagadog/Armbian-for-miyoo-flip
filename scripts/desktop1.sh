#!/bin/bash
# Stage 1: inside the arm64 rootfs, point apt at a fast local mirror and install
# the XFCE desktop stack.  Runs under qemu-user via binfmt.
set -e
R=/mnt/miyoo-root

# --- mirror selection -------------------------------------------------------
cat > "$R/etc/apt/sources.list.d/debian.sources" <<'EOF'
Types: deb
URIs: https://mirrors.tuna.tsinghua.edu.cn/debian
Suites: trixie trixie-updates trixie-backports
Components: main contrib non-free non-free-firmware
Signed-By: /usr/share/keyrings/debian-archive-keyring.gpg

Types: deb
URIs: https://mirrors.tuna.tsinghua.edu.cn/debian-security
Suites: trixie-security
Components: main contrib non-free non-free-firmware
Signed-By: /usr/share/keyrings/debian-archive-keyring.gpg
EOF

cat > "$R/etc/apt/sources.list.d/armbian.sources" <<'EOF'
Types: deb
URIs: https://mirrors.tuna.tsinghua.edu.cn/armbian
Suites: trixie
Components: main trixie-utils trixie-desktop
Signed-By: /usr/share/keyrings/armbian-archive-keyring.gpg
EOF

# configng repo is only useful with network tooling; keep apt quiet.
mv "$R/etc/apt/sources.list.d/armbian-config.sources" \
   "$R/etc/apt/sources.list.d/armbian-config.sources.disabled" 2>/dev/null || true

# --- chroot plumbing --------------------------------------------------------
for d in proc sys dev dev/pts; do
    mountpoint -q "$R/$d" || mount --bind "/$d" "$R/$d"
done
cp /etc/resolv.conf "$R/etc/resolv.conf"

# Don't let package maintainer scripts start services in the chroot.
cat > "$R/usr/sbin/policy-rc.d" <<'EOF'
#!/bin/sh
exit 101
EOF
chmod +x "$R/usr/sbin/policy-rc.d"

install -m 755 /usr/bin/qemu-aarch64-static "$R/usr/bin/qemu-aarch64-static"

echo "=== apt update ==="
chroot "$R" /usr/bin/env DEBIAN_FRONTEND=noninteractive apt-get update 2>&1 | tail -8

echo "=== install desktop core ==="
chroot "$R" /usr/bin/env DEBIAN_FRONTEND=noninteractive \
    apt-get install -y --no-install-recommends \
    xfce4 xfce4-terminal lightdm lightdm-gtk-greeter \
    xserver-xorg xserver-xorg-input-libinput libgl1-mesa-dri \
    dbus-x11 x11-xserver-utils fonts-dejavu-core sudo network-manager \
    2>&1 | tail -20

echo "=== install antimicrox / onboard ==="
chroot "$R" /usr/bin/env DEBIAN_FRONTEND=noninteractive \
    apt-get install -y --no-install-recommends antimicrox onboard 2>&1 | tail -12 \
    || echo "WARN: antimicrox/onboard install failed"

echo "=== install audio ==="
chroot "$R" /usr/bin/env DEBIAN_FRONTEND=noninteractive \
    apt-get install -y --no-install-recommends \
    pipewire pipewire-pulse wireplumber xfce4-pulseaudio-plugin 2>&1 | tail -8 \
    || echo "WARN: audio stack install failed"

echo "=== result ==="
chroot "$R" /usr/bin/env bash -c 'ls /usr/share/xsessions/; which startxfce4 lightdm antimicrox onboard 2>/dev/null'
echo "=== disk ==="
df -h "$R"
echo STAGE1_DONE
