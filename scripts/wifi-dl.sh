#!/bin/bash
set -e
cd /home/wang/miyoo-build
mkdir -p rtl8733bu
cd rtl8733bu
PIN=c46aa25e237cb43f33390cf58eee5c69d9b32883
URL="https://github.com/Awesome-Embedded-Learning-Studio/rtl8733bu-linux-driver/archive/$PIN.tar.gz"
if [ ! -f src.tar.gz ]; then
    curl -sL --retry 8 --retry-all-errors --max-time 600 -o src.tar.gz "$URL"
fi
ls -l src.tar.gz
rm -rf drv && mkdir drv && tar -xf src.tar.gz -C drv --strip-components=1
ls drv | head -20
echo "=== Makefile head ==="
head -30 drv/Makefile
