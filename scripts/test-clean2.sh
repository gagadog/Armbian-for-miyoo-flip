#!/bin/bash
cd "/mnt/d/wendang/默认项目/miyoo-flip-dtb" || exit 1
python3 scripts/clean-panel-xml.py device/xfce4-panel.xml /tmp/panel-clean.xml
echo
echo "=== xml sanity: panels / ids ==="
grep -nE 'name="panels"|name="panel-[0-9]+"|name="plugin-ids"' /tmp/panel-clean.xml | head
echo
echo "=== the panels array block ==="
sed -n '/<property name="panels" type="array">/,/<property name="panel-1"/p' /tmp/panel-clean.xml
echo "=== xml well-formed? ==="
python3 -c "import xml.etree.ElementTree as ET; ET.parse('/tmp/panel-clean.xml'); print('  OK')"
