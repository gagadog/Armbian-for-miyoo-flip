#!/bin/sh
echo "=== start antimicrox with the stick profile ==="
pgrep -f 'antimicrox --profile' >/dev/null || \
  su - miyoo -c "DISPLAY=:0 XAUTHORITY=/home/miyoo/.Xauthority setsid nohup /home/miyoo/.local/bin/antimicrox-logged >/dev/null 2>&1 &"
sleep 4
ps ax -o pid,user,args | grep -i 'antimicrox --profile' | grep -v grep || echo "not running"

echo
echo "=== antimicrox log ==="
tail -5 /home/miyoo/antimicrox.log 2>/dev/null

echo
echo "=== 45s pointer tracking (move the LEFT stick now) ==="
su - miyoo -c "DISPLAY=:0 XAUTHORITY=/home/miyoo/.Xauthority setsid nohup python3 /tmp/ptrtrack.py >/dev/null 2>&1 &"
sleep 1
echo "tracking..."
