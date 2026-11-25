#!/bin/bash
M="https://mirrors.tuna.tsinghua.edu.cn/armbian-releases/"
for b in anbernic-rg-ds anbernic-rg-vita-pro radxa-zero3; do
    echo "================ $b ================"
    curl -s --max-time 40 "$M$b/archive/" \
      | grep -oE 'href="[^"?][^"]*minimal[^"]*\.img\.xz"' \
      | sed 's/href="//;s/"//' | sort -u
    echo
done
