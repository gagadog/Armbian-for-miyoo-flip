#!/bin/bash
# Generate a dedicated debug keypair (private key stays on this PC only).
set -e
K="/mnt/d/wendang/默认项目/miyoo-flip-dtb/keys"
mkdir -p "$K"
chmod 700 "$K"
if [ ! -f "$K/miyoo_debug" ]; then
    ssh-keygen -t ed25519 -N '' -C 'miyoo-flip-debug' -f "$K/miyoo_debug" >/dev/null
fi
chmod 600 "$K/miyoo_debug"
echo "=== public key ==="
cat "$K/miyoo_debug.pub"
ls -l "$K"
