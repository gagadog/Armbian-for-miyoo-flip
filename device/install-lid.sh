#!/bin/sh
set -e

echo "=== install daemon ==="
install -m 755 /tmp/miyoo-lid.py /usr/local/bin/miyoo-lid
python3 -c "import ast;ast.parse(open('/usr/local/bin/miyoo-lid').read())" && echo "  syntax ok"

cat > /etc/systemd/system/miyoo-lid.service <<'EOF'
[Unit]
Description=Miyoo Flip lid switch (backlight off on close)
After=systemd-modules-load.service
StartLimitIntervalSec=0

[Service]
Type=simple
ExecStart=/usr/bin/python3 /usr/local/bin/miyoo-lid
Restart=always
RestartSec=3

[Install]
WantedBy=multi-user.target
EOF
ln -sf /etc/systemd/system/miyoo-lid.service \
       /etc/systemd/system/multi-user.target.wants/miyoo-lid.service

echo "=== stop logind from suspending on lid close ==="
mkdir -p /etc/systemd/logind.conf.d
cat > /etc/systemd/logind.conf.d/miyoo-lid.conf <<'EOF'
# The suspend path is not wired up on mainline for this board, so logind must
# not suspend when the lid closes.  miyoo-lid.service blanks the backlight.
[Login]
HandleLidSwitch=ignore
HandleLidSwitchExternalPower=ignore
HandleLidSwitchDocked=ignore
EOF
cat /etc/systemd/logind.conf.d/miyoo-lid.conf

echo
echo "=== backlight before ==="
cat /sys/class/backlight/backlight/brightness

echo
echo "=== end-to-end test with a synthetic SW_LID device ==="
python3 - <<'PY'
import os, subprocess, sys, time
import evdev
from evdev import UInput, ecodes as e

ui = UInput({e.EV_SW: [e.SW_LID]}, name="fake-lid", bustype=e.BUS_USB)
path = ui.device.path
print("fake lid:", path)
time.sleep(0.5)

env = dict(os.environ, MIYOO_LID=path)
d = subprocess.Popen([sys.executable, "/usr/local/bin/miyoo-lid"], env=env,
                     stdout=subprocess.DEVNULL, stderr=subprocess.PIPE, text=True)
time.sleep(1.5)

BL = "/sys/class/backlight/backlight/brightness"
def rd():
    return int(open(BL).read().strip())

print("initial brightness:", rd())

ui.write(e.EV_SW, e.SW_LID, 1); ui.syn()
time.sleep(1.0)
closed = rd()
print("after close       :", closed)

ui.write(e.EV_SW, e.SW_LID, 0); ui.syn()
time.sleep(1.0)
opened = rd()
print("after open        :", opened)

print("RESULT:", "OK" if closed == 0 and opened > 0 else "FAILED")

d.terminate()
ui.close()
PY
