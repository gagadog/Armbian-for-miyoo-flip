#!/bin/bash
M="https://mirrors.tuna.tsinghua.edu.cn/armbian-releases/"
echo "=== all boards ==="
cat /tmp/boards.txt 2>/dev/null | tr '\n' ' '
echo
echo
for b in anbernic-rg-ds anbernic-rg-vita-pro radxa-e25 radxa-zero3 rock-3a; do
    echo "================ $b ================"
    curl -s --max-time 30 "$M$b/" | grep -oE 'href="[^"?][^"]*"' | sed 's/href="//;s/"//' | grep -v '^\.\./$' | head -20
    echo
done
