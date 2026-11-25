#!/bin/sh
echo "=== run padmouse against a fake pad, capture everything ==="
python3 /tmp/fakepad.py > /tmp/fake.node 2>/tmp/fake.err &
FAKE=$!
sleep 1
NODE=$(head -1 /tmp/fake.node)
echo "fake node: $NODE"

MIYOO_PAD="$NODE" /usr/bin/python3 /usr/local/bin/miyoo-padmouse > /tmp/pm.out 2> /tmp/pm.err &
PM=$!
sleep 1.5
echo "--- input devices while running ---"
for d in /sys/class/input/event*; do echo "  $(basename $d)  $(cat $d/device/name 2>/dev/null)"; done
echo
sleep 2
kill $PM 2>/dev/null
wait $FAKE 2>/dev/null
echo "--- daemon stderr ---"
cat /tmp/pm.err
echo "--- daemon stdout ---"
cat /tmp/pm.out
echo
echo "=== does X see the device? ==="
DISPLAY=:0 XAUTHORITY=/home/miyoo/.Xauthority xinput list 2>&1 | head -20 || echo "xinput not installed"
