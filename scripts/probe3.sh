#!/bin/bash
echo "=== v7.x kernel mirror ==="
curl -s --max-time 30 https://mirrors.tuna.tsinghua.edu.cn/kernel/ | grep -oE 'href="v[0-9]+\.x/"' | head
echo "--- 7.3.x ---"
curl -s --max-time 40 https://mirrors.tuna.tsinghua.edu.cn/kernel/v7.x/ | grep -oE 'linux-7\.3\.[0-9]+\.tar\.xz' | sort -uV | tail -8
echo
echo "=== image HEAD ==="
curl -sIL --max-time 30 "https://mirrors.tuna.tsinghua.edu.cn/armbian-releases/anbernic-rg-ds/archive/Armbian_26.11.2_Anbernic-rg-ds_trixie_edge_7.3.5_minimal.img.xz" | grep -iE '^(HTTP/|content-length:)'
