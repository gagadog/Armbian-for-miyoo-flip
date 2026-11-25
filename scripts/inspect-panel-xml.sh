#!/bin/bash
F="/mnt/d/wendang/默认项目/miyoo-flip-dtb/device/xfce4-panel.xml"
echo "=== panels array ==="
sed -n '/name="panels"/,/^    <\/property>/p' "$F" | head -30
echo
echo "=== panel-1 / panel-2 blocks (names only) ==="
grep -nE 'name="panel-[0-9]+" type="empty"' "$F"
echo
echo "=== each panel's plugin-ids ==="
awk '
  /name="panel-[0-9]+" type="empty"/ { panel=$0; gsub(/.*name="/,"",panel); gsub(/".*/,"",panel); print "--- " panel }
  /name="plugin-ids"/ { inids=1; print "    ids:"; next }
  inids && /<value type="int" value="[0-9]+"/ { v=$0; gsub(/.*value="/,"",v); gsub(/".*/,"",v); print "      " v }
  inids && /<\/property>/ { inids=0 }
' "$F"
