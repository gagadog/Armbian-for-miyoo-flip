#!/bin/sh
# Start antimicrox (if needed) and run the synthetic-pad test on the live display.
echo "=== start antimicrox ==="
pkill -f antimicrox-logged 2>/dev/null || true
pkill -f 'antimicrox --profile' 2>/dev/null || true
sleep 1
su - miyoo -c "DISPLAY=:0 XAUTHORITY=/home/miyoo/.Xauthority setsid nohup /home/miyoo/.local/bin/antimicrox-logged >/dev/null 2>&1 &"
sleep 6
ps ax -o pid,args | grep 'antimicrox' | grep -v grep || echo "antimicrox NOT running"

echo
echo "=== input devices now ==="
for d in /sys/class/input/event*; do
    echo "  $(basename "$d")  $(cat "$d/device/name" 2>/dev/null)"
done

echo
echo "=== synthetic pad test ==="
su - miyoo -c "DISPLAY=:0 XAUTHORITY=/home/miyoo/.Xauthority python3 /tmp/test_amx.py" 2>&1

echo
echo "=== antimicrox log ==="
tail -8 /home/miyoo/antimicrox.log 2>/dev/null
