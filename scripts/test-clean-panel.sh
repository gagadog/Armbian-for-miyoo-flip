#!/bin/bash
cd "/mnt/d/wendang/默认项目/miyoo-flip-dtb" || exit 1
cp device/xfce4-panel.xml /tmp/panel-test.xml
python3 scripts/xml-clean-panel.py /tmp/panel-test.xml
echo "--- panels ---"
grep -oE 'name="panel-[0-9]+" type="empty"' /tmp/panel-test.xml
echo "--- plugin decls ---"
grep -cE 'name="plugin-[0-9]+" type="string"' /tmp/panel-test.xml
echo "--- panel-1 plugin-ids ---"
awk '/name="panel-1"/{p=1} p&&/name="plugin-ids"/{i=1;next} i&&/<value type="int"/{print "  "$0} i&&/<\/property>/{exit}' /tmp/panel-test.xml
