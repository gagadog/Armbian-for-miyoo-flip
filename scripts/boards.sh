#!/bin/bash
M="https://mirrors.tuna.tsinghua.edu.cn/armbian-releases/"
echo "=== boards (rk35 / rockchip related) ==="
curl -s --max-time 40 "$M" | grep -oE 'href="[^"?/][^"]*/"' | sed 's/href="//;s/"//' | tr -d '/' > /tmp/boards.txt
wc -l < /tmp/boards.txt
grep -iE 'opi|orange|rock|radxa|quartz|powkiddy|anbernic|rk35|e25|cm3|zero3|tspi|lubancat|roc' /tmp/boards.txt
