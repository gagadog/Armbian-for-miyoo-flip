#!/bin/bash
set -e
cd /home/wang/miyoo-build/debs

PKGS="network-manager-applet nm-connection-editor libnma0 libnma-common \
      libayatana-appindicator3-1 libayatana-indicator3-7 libmm-glib0 \
      libgck-2-2 libgcr-4-4 libsecret-1-0 xfce-polkit \
      mobile-broadband-provider-info libjansson4"

for p in $PKGS; do
    fn=$(awk -v pkg="$p" '$1=="Package:" && $2==pkg {f=1} f && $1=="Filename:" {print $2; exit}' Packages)
    if [ -z "$fn" ]; then
        echo "  $p -> NOT FOUND"
        continue
    fi
    base=$(basename "$fn")
    if [ ! -f "$base" ]; then
        curl -sL --retry 3 --max-time 300 -O "https://mirrors.tuna.tsinghua.edu.cn/debian/$fn" || echo "  download failed: $base"
    fi
    printf '  %-38s %s\n' "$base" "$(stat -c %s "$base" 2>/dev/null) bytes"
done

echo
echo "=== total ==="
ls -1 *.deb | wc -l
du -sh .
