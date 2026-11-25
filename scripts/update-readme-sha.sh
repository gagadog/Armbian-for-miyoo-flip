#!/bin/bash
cd "/mnt/d/wendang/默认项目/miyoo-flip-dtb" || exit 1
SIZE=$(stat -c %s image/Armbian-MiyooFlip_26.11.2_trixie_edge_7.3.5_xfce_v7.img.xz)
SHA=$(sha256sum image/Armbian-MiyooFlip_26.11.2_trixie_edge_7.3.5_xfce_v7.img.xz | cut -d' ' -f1)
echo "size=$SIZE sha=$SHA"

# v6 -> v7 里所有镜像名
sed -i 's/xfce_v6\.img\.xz/xfce_v7.img.xz/g' README.md DEVELOPMENT.md

# 更新信息表
sed -i "s#^| 压缩包 | .*#| 压缩包 | ${SIZE} 字节（$(numfmt --to=iec $SIZE)），\`xz -t\` 通过 |#" README.md
sed -i "s#^| SHA-256 | .*#| SHA-256 | \`${SHA}\` |#" README.md

grep -n '压缩包\|SHA-256 |' README.md
echo "--- 镜像名 ---"
grep -n 'img.xz' README.md | head -5
