#!/bin/bash
cd "/mnt/d/wendang/默认项目/miyoo-flip-dtb" || exit 1
echo "=== panel xml: plugin-12 must be gone ==="
if grep -q 'plugin-12' device/xfce4-panel.xml; then
    echo "  STILL PRESENT - fixing"
    python3 scripts/drop-pulse-plugin.py device/xfce4-panel.xml
else
    echo "  ok, no plugin-12"
fi
echo "=== plugin ids ==="
awk '/name="plugin-ids"/{i=1;next} i&&/<value type="int"/{n++} i&&/<\/property>/{print "  count: "n; exit}' device/xfce4-panel.xml
echo "=== xml valid? ==="
python3 -c "import xml.etree.ElementTree as ET; ET.parse('device/xfce4-panel.xml'); print('  OK')"
echo
echo "=== debs present (pnmixer etc) ==="
for d in pnmixer libnotify4 xfce4-power-manager-plugins network-manager-applet lxpolkit lxsession-data; do
    f=$(ls /home/wang/miyoo-build/debs/${d}_*.deb 2>/dev/null | head -1)
    printf '  %-30s %s\n' "$d" "${f:-(missing)}"
done
