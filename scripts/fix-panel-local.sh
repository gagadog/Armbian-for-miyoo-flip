#!/bin/bash
cd "/mnt/d/wendang/默认项目/miyoo-flip-dtb" || exit 1
echo "=== before ==="
grep -cE 'plugin-12|value="12"' device/xfce4-panel.xml || true
python3 scripts/drop-pulse-plugin.py device/xfce4-panel.xml
echo "=== after ==="
grep -E 'plugin-1[0-9]" type="string"|value="12"' device/xfce4-panel.xml || echo "  (plugin-12 gone)"
echo "=== panel-1 plugin-ids ==="
awk '/name="panel-1"/{p=1} p&&/name="plugin-ids"/{i=1;next} i&&/<value type="int"/{printf "%s ", $0} i&&/<\/property>/{exit}' device/xfce4-panel.xml
echo
echo "=== xml well-formed? ==="
python3 -c "import xml.etree.ElementTree as ET; ET.parse('device/xfce4-panel.xml'); print('  OK')"
