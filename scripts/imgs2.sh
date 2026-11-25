#!/bin/bash
M="https://mirrors.tuna.tsinghua.edu.cn/armbian-releases/anbernic-rg-ds/archive/"
echo "=== all images for this board ==="
curl -s --max-time 40 "$M" | grep -oE 'href="[^"?][^"]*\.img\.xz"' | sed 's/href="//;s/"//' | sort -u
