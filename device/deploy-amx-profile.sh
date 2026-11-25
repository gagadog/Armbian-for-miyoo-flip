#!/bin/sh
echo "=== install antimicrox profile ==="
cp /tmp/miyoo-mouse.amgp /home/miyoo/.config/antimicrox/profiles/miyoo-mouse.amgp
cp /tmp/miyoo-mouse.amgp /home/miyoo/.local/share/antimicrox/profiles/miyoo-mouse.amgp 2>/dev/null || true
ls -l /home/miyoo/.config/antimicrox/profiles/miyoo-mouse.amgp
grep -c 'stickbutton' /home/miyoo/.config/antimicrox/profiles/miyoo-mouse.amgp

echo "=== restart antimicrox ==="
pkill -f antimicrox-logged 2>/dev/null || true
pkill -f 'antimicrox --profile' 2>/dev/null || true
sleep 1

echo "=== start 60s stick capture ==="
sed -i 's/time.time() + 45/time.time() + 60/; s/time.time() + 30/time.time() + 60/' /tmp/sticklog.py
setsid nohup python3 /tmp/sticklog.py >/dev/null 2>&1 &
sleep 1
echo "capture running (60s)"
