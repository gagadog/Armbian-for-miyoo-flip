#!/bin/bash
set -e
export DEBIAN_FRONTEND=noninteractive
apt-get install -y qemu-user-static binfmt-support 2>&1 | tail -6
echo "=== register ==="
update-binfmts --enable qemu-aarch64 2>&1 || true
update-binfmts --display qemu-aarch64 2>&1 | head -8
echo "=== binfmt entries ==="
ls /proc/sys/fs/binfmt_misc/ | grep -i aarch64 || echo "no aarch64 entry"
echo "=== quick test ==="
if [ -x /usr/bin/qemu-aarch64-static ]; then
    echo "qemu present"
fi
