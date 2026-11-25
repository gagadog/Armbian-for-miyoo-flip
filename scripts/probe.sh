#!/bin/bash
M="https://mirrors.tuna.tsinghua.edu.cn/armbian/"
echo "=== root ==="
curl -s --max-time 30 "$M" | grep -oE 'href="[^"]+"' | head -40
