#!/bin/bash
# Decode a DTB and show the board-identity / key nodes.
set -e
cd "/mnt/d/wendang/默认项目/miyoo-flip-dtb/out"
for f in rk3566-miyoo-flip-armbian-6.12.dtb rk3566-miyoo-flip-armbian-6.6.dtb; do
	echo "================ $f ================"
	dtc -I dtb -O dts "$f" -o /tmp/dec.dts 2>/dev/null
	grep -nE 'model = |^[[:space:]]*compatible = "miyoo|panel_description|gpio-keys-polled|stdout-path' /tmp/dec.dts | head
	echo "-- nodes of interest --"
	grep -cE '^\s+(button|sw)[0-9]+ \{' /tmp/dec.dts || true
	awk '/panel@0 \{/,/^\t\t\};/' /tmp/dec.dts | head -8
	echo
done
