#!/bin/bash
set -e
cd /home/wang/miyoo-build/firmware
URL="https://github.com/KeatenPerkins/butterflyOS/releases/download/v1.9.0/ButterflyOS-Miyoo-Flip-V2-20261125.tar"
if [ ! -f os.tar ]; then
    echo "downloading $(basename $URL) ..."
    curl -L --retry 5 --retry-all-errors --max-time 3600 -o os.tar "$URL"
fi
ls -lh os.tar
echo
echo "=== listing entries mentioning 8733 ==="
tar -tf os.tar 2>/dev/null | grep -i 8733 | head -40
echo
echo "=== firmware dirs ==="
tar -tf os.tar 2>/dev/null | grep -iE '/firmware/(rtl|.*8733)' | head -20
echo
echo "=== top-level shape ==="
tar -tf os.tar 2>/dev/null | head -15
