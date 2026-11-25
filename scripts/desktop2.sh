#!/bin/bash
# Stage 2: user account, autologin, XFCE session defaults, antimicrox profile,
# on-screen keyboard.  Runs on the mounted rootfs (no chroot needed for files,
# chroot only for passwd/useradd).
set -e
R=/mnt/miyoo-root
U=miyoo
UHOME="$R/home/$U"

for d in proc sys dev dev/pts; do
    mountpoint -q "$R/$d" || mount --bind "/$d" "$R/$d"
done

echo "=== extra packages ==="
# polkitd: power/logout actions in the XFCE session menu
# fonts-noto-cjk: otherwise every Chinese string renders as tofu
# xfce4-power-manager: battery/lid handling in the panel
if mountpoint -q "$R/etc/resolv.conf"; then
    echo "resolv.conf already bind-mounted"
else
    rm -f "$R/etc/resolv.conf"; touch "$R/etc/resolv.conf"
    mount --bind /etc/resolv.conf "$R/etc/resolv.conf"
fi
chroot "$R" /usr/bin/env DEBIAN_FRONTEND=noninteractive \
    apt-get install -y --no-install-recommends polkitd xfce4-power-manager fonts-noto-cjk \
    2>&1 | tail -5 || echo "WARN extras"

echo "=== uinput / joydev autoload ==="
mkdir -p "$R/etc/modules-load.d"
printf 'uinput\njoydev\n' > "$R/etc/modules-load.d/uinput.conf"
cat "$R/etc/modules-load.d/uinput.conf"

echo "=== user $U ==="
if ! chroot "$R" id "$U" >/dev/null 2>&1; then
    chroot "$R" useradd -m -u 1000 -s /bin/bash -G sudo,video,render,input,audio,plugdev,netdev,bluetooth "$U"
fi
echo "$U:$U" | chroot "$R" chpasswd
chroot "$R" usermod -aG sudo,video,render,input,audio,plugdev,netdev,bluetooth "$U" || true
chroot "$R" id "$U"

echo "=== lightdm autologin ==="
mkdir -p "$R/etc/lightdm/lightdm.conf.d"
cat > "$R/etc/lightdm/lightdm.conf.d/60-miyoo-autologin.conf" <<EOF
[Seat:*]
autologin-user=$U
autologin-user-timeout=0
autologin-session=xfce
user-session=xfce
greeter-session=lightdm-gtk-greeter
EOF

echo "=== default target: graphical ==="
chroot "$R" systemctl set-default graphical.target >/dev/null 2>&1 || true
chroot "$R" systemctl enable lightdm >/dev/null 2>&1 || true

echo "=== xfce session ==="
mkdir -p "$UHOME/.config/xfce4" "$UHOME/.config/autostart" \
         "$UHOME/.config/xfce4/xfconf/xfce-perchannel-xml" \
         "$UHOME/.local/share/antimicrox/profiles" \
         "$UHOME/.config/antimicrox/profiles" \
         "$UHOME/Desktop"

# 640x480 panel: keep it thin and auto-hiding so the screen stays usable
cat > "$UHOME/.config/xfce4/xfconf/xfce-perchannel-xml/xfce4-panel.xml" <<'EOF'
<?xml version="1.0" encoding="UTF-8"?>
<channel name="xfce4-panel" version="1.0">
  <property name="configver" type="int" value="2"/>
  <property name="panels" type="array">
    <value type="int" value="1"/>
    <property name="panel-1" type="empty">
      <property name="position" type="string" value="p=6;x=0;y=0"/>
      <property name="length" type="uint" value="100"/>
      <property name="position-locked" type="bool" value="true"/>
      <property name="size" type="uint" value="30"/>
      <property name="autohide-behavior" type="uint" value="2"/>
      <property name="plugin-ids" type="array">
        <value type="int" value="1"/>
        <value type="int" value="2"/>
        <value type="int" value="3"/>
        <value type="int" value="4"/>
        <value type="int" value="5"/>
        <value type="int" value="6"/>
      </property>
    </property>
  </property>
  <property name="plugins" type="empty">
    <property name="plugin-1" type="string" value="applicationsmenu"/>
    <property name="plugin-2" type="string" value="launcher">
      <property name="items" type="array">
        <value type="string" value="onboard.desktop"/>
      </property>
    </property>
    <property name="plugin-3" type="string" value="tasklist">
      <property name="grouping" type="uint" value="1"/>
    </property>
    <property name="plugin-4" type="string" value="separator"/>
    <property name="plugin-5" type="string" value="systray"/>
    <property name="plugin-6" type="string" value="clock"/>
  </property>
</channel>
EOF

echo "=== antimicrox mouse profile ==="
# SDL enumerates evdev BTN_* in ascending code order, so for this pad:
#  0 BTN_SOUTH  1 BTN_EAST  2 BTN_NORTH  3 BTN_WEST
#  4 BTN_TL     5 BTN_TR    6 BTN_TL2    7 BTN_TR2
#  8 BTN_SELECT 9 BTN_START 10 BTN_MODE 11 BTN_THUMBL 12 BTN_THUMBR
# 13 BTN_DPAD_UP 14 BTN_DPAD_DOWN 15 BTN_DPAD_LEFT 16 BTN_DPAD_RIGHT
# XML uses 1-based indices.
cat > "$UHOME/.config/antimicrox/profiles/miyoo-mouse.amgp" <<'EOF'
<?xml version="1.0" encoding="UTF-8"?>
<joystick configversion="24">
  <sets>
    <set index="1">
      <!-- D-pad moves the pointer -->
      <button index="14"><slots><slot><code>1</code><mode>mousemovement</mode></slot></slots></button>
      <button index="15"><slots><slot><code>2</code><mode>mousemovement</mode></slot></slots></button>
      <button index="16"><slots><slot><code>3</code><mode>mousemovement</mode></slot></slots></button>
      <button index="17"><slots><slot><code>4</code><mode>mousemovement</mode></slot></slots></button>
      <!-- A = left click, B = right click, Y = middle click -->
      <button index="1"><slots><slot><code>1</code><mode>mousebutton</mode></slot></slots></button>
      <button index="2"><slots><slot><code>3</code><mode>mousebutton</mode></slot></slots></button>
      <button index="4"><slots><slot><code>2</code><mode>mousebutton</mode></slot></slots></button>
      <!-- L1/R1 scroll up/down -->
      <button index="5"><slots><slot><code>4</code><mode>mousebutton</mode></slot></slots></button>
      <button index="6"><slots><slot><code>5</code><mode>mousebutton</mode></slot></slots></button>
      <!-- Start = Enter, Select = Escape, X = Backspace -->
      <button index="10"><slots><slot><code>16777220</code><mode>keyboard</mode></slot></slots></button>
      <button index="9"><slots><slot><code>16777216</code><mode>keyboard</mode></slot></slots></button>
      <button index="3"><slots><slot><code>16777219</code><mode>keyboard</mode></slot></slots></button>
    </set>
  </sets>
</joystick>
EOF
cp "$UHOME/.config/antimicrox/profiles/miyoo-mouse.amgp" \
   "$UHOME/.local/share/antimicrox/profiles/miyoo-mouse.amgp"

echo "=== autostart entries ==="
cat > "$UHOME/.config/autostart/antimicrox.desktop" <<EOF
[Desktop Entry]
Type=Application
Name=AntiMicroX (mouse mode)
Comment=Map the gamepad to the mouse pointer
Exec=antimicrox --profile %h/.config/antimicrox/profiles/miyoo-mouse.amgp --hidden
Icon=antimicrox
Terminal=false
X-GNOME-Autostart-enabled=true
EOF
sed -i "s|%h|/home/$U|" "$UHOME/.config/autostart/antimicrox.desktop"

cat > "$UHOME/.config/autostart/no-blank.desktop" <<'EOF'
[Desktop Entry]
Type=Application
Name=Disable screen blanking
Exec=sh -c "xset s off -dpms; xset s noblank"
Terminal=false
X-GNOME-Autostart-enabled=true
EOF

if chroot "$R" test -x /usr/bin/onboard; then
cat > "$UHOME/.config/autostart/onboard.desktop" <<'EOF'
[Desktop Entry]
Type=Application
Name=Onboard
Comment=On-screen keyboard
Exec=onboard
Icon=onboard
Terminal=false
X-GNOME-Autostart-enabled=true
EOF
fi

echo "=== desktop shortcut for the keyboard ==="
cat > "$UHOME/Desktop/onboard.desktop" <<'EOF'
[Desktop Entry]
Type=Application
Name=Onboard
Comment=On-screen keyboard
Exec=onboard
Icon=onboard
Terminal=false
EOF

echo "=== ownership ==="
chroot "$R" chown -R 1000:1000 "/home/$U"

echo "=== restore resolv.conf symlink ==="
umount "$R/etc/resolv.conf" 2>/dev/null || true
rm -f "$R/etc/resolv.conf"
ln -s /run/systemd/resolve/stub-resolv.conf "$R/etc/resolv.conf"
ls -l "$R/etc/resolv.conf"

echo "=== cleanup ==="
rm -f "$R/usr/sbin/policy-rc.d" "$R/usr/bin/qemu-aarch64-static"
chroot "$R" apt-get clean || true
rm -rf "$R/var/lib/apt/lists"/*
mkdir -p "$R/var/lib/apt/lists/partial"
df -h "$R"
echo STAGE2_DONE
