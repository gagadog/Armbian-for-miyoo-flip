#!/bin/sh
echo "=== X / session ==="
pgrep -af 'lightdm|Xorg|xfce4-panel|xfce4-session|xfce4-power-manager|nm-applet' | head -20
echo
echo "=== logind lid setting (loaded) ==="
systemctl show systemd-logind -p HandleLidSwitch -p HandleLidSwitchDocked 2>/dev/null
echo "--- conf file ---"
cat /etc/systemd/logind.conf.d/miyoo-lid.conf 2>/dev/null
echo
echo "=== inhibitor / sleep state ==="
systemctl status sleep.target 2>/dev/null | head -4
echo
echo "=== panel config: plugin-ids ==="
DISPLAY=:0 XAUTHORITY=/home/miyoo/.Xauthority xfconf-query -c xfce4-panel -p /panels/panel-1/plugin-ids 2>&1 | head -20
echo "--- xml ids ---"
sed -n '/name="plugin-ids"/,/<\/property>/p' /home/miyoo/.config/xfce4/xfconf/xfce-perchannel-xml/xfce4-panel.xml 2>/dev/null | head -20
echo
echo "=== greeter / display manager ==="
systemctl is-active lightdm
echo
echo "=== lid switch state ==="
python3 - <<'PY'
import glob, evdev
for p in sorted(glob.glob('/dev/input/event*')):
    try:
        d = evdev.InputDevice(p)
    except Exception:
        continue
    caps = d.capabilities()
    if 5 in caps and evdev.ecodes.SW_LID in caps[5]:
        print(" ", d.name, "active:", d.active_keys())
        break
PY
