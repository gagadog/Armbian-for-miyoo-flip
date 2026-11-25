#!/bin/bash
# Probe Armbian mirrors for RK3566 (rk35xx) images.
MIRRORS="
https://mirrors.tuna.tsinghua.edu.cn/armbian/
https://mirror.nju.edu.cn/armbian/
https://mirrors.bfsu.edu.cn/armbian/
https://mirrors.ustc.edu.cn/armbian/
"

for m in $MIRRORS; do
    code=$(curl -s -o /dev/null -w '%{http_code}' --max-time 20 "$m")
    echo "== $m -> HTTP $code"
done

echo
echo "== look for rk35xx / rk3566 index =="
for m in $MIRRORS; do
    for sub in "dl/" "" ; do
        body=$(curl -s --max-time 25 "${m}${sub}" 2>/dev/null | head -c 4000)
        if echo "$body" | grep -qi "rk35"; then
            echo "--- ${m}${sub} contains rk35 links ---"
            echo "$body" | grep -oiE 'href="[^"]*rk35[^"]*"' | head -20
        fi
    done
done
