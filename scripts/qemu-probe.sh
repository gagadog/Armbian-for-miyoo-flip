#!/bin/bash
echo "=== existing qemu ==="
ls /usr/bin/qemu-aarch64* 2>/dev/null || echo "no qemu-aarch64"
echo "=== binfmt_misc ==="
ls /proc/sys/fs/binfmt_misc/ 2>/dev/null | head || echo "not mounted"
echo "=== apt sources ==="
grep -rhE '^(deb|URIs)' /etc/apt/sources.list /etc/apt/sources.list.d/*.sources 2>/dev/null | head -10
echo "=== apt update (dry) ==="
timeout 90 apt-get update -o Acquire::Retries=2 2>&1 | tail -5
echo "exit=$?"
