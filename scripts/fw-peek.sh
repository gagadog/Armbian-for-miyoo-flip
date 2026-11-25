#!/bin/bash
set -e
cd /home/wang/miyoo-build
mkdir -p firmware
cd firmware
URL="https://github.com/KeatenPerkins/butterflyOS/releases/download/v1.9.0/ButterflyOS-Miyoo-Flip-V2-20261125.tar"
echo "=== fetch first 40MB ==="
curl -sL --retry 3 --max-time 300 -r 0-41943039 -o head.tar "$URL" || true
ls -l head.tar
echo
echo "=== tar listing (what we could read) ==="
tar -tf head.tar 2>/dev/null | head -40 || echo "(tar could not parse)"
echo
echo "=== any 8733 entries ==="
tar -tf head.tar 2>/dev/null | grep -i 8733 | head -20 || echo "(none in first 40MB)"
