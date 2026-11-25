#!/bin/bash
M="https://mirrors.tuna.tsinghua.edu.cn/armbian-releases/"
echo "=== archive ==="
curl -s --max-time 40 "$M"archive/ | grep -oE 'href="[^"?][^"]*"' | sed 's/href="//;s/"//' | grep -vE '^https?:|^/static|^/assets|^/feed' | head -20
echo
echo "=== rock-3a/archive ==="
curl -s --max-time 40 "$M"rock-3a/archive/ | grep -oE 'href="[^"?][^"]*\.(img\.xz|img\.asc|sha)' | sed 's/href="//;s/"//' | head -40
