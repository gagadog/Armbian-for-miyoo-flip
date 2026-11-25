#!/bin/sh
# Rename the device to Miyoo Flip, install the new antimicrox profile, and
# restart antimicrox so the mapping takes effect.
set -e

echo "=== identity ==="
echo "before: $(hostname) / $(grep -E '^BOARD' /etc/armbian-release | tr '\n' ' ')"
echo "miyoo-flip" > /etc/hostname
hostname miyoo-flip 2>/dev/null || true
sed -i 's/^127\.0\.1\.1.*/127.0.1.1\tmiyoo-flip/' /etc/hosts
grep -q '127.0.1.1' /etc/hosts || echo "127.0.1.1	miyoo-flip" >> /etc/hosts

sed -i 's/^BOARD=.*/BOARD=miyoo-flip/' /etc/armbian-release
sed -i 's/^BOARD_NAME=.*/BOARD_NAME="Miyoo Flip"/' /etc/armbian-release
sed -i 's/^BOARD_TYPE=.*/BOARD_TYPE="conf"/' /etc/armbian-release
echo "after:  $(hostname) / $(grep -E '^BOARD' /etc/armbian-release | tr '\n' ' ')"

# Armbian also keeps a copy used by armbian-config / MOTD
[ -f /etc/armbian-image-release ] && sed -i 's/^BOARD_NAME=.*/BOARD_NAME="Miyoo Flip"/' /etc/armbian-image-release || true

echo
echo "=== antimicrox profile ==="
install -d -o 1000 -g 1000 /home/miyoo/.config/antimicrox/profiles
install -m 644 -o 1000 -g 1000 /tmp/miyoo-mouse.amgp \
        /home/miyoo/.config/antimicrox/profiles/miyoo-mouse.amgp
install -d -o 1000 -g 1000 /home/miyoo/.local/share/antimicrox/profiles
install -m 644 -o 1000 -g 1000 /tmp/miyoo-mouse.amgp \
        /home/miyoo/.local/share/antimicrox/profiles/miyoo-mouse.amgp
grep -c 'button index' /home/miyoo/.config/antimicrox/profiles/miyoo-mouse.amgp

echo
echo "=== desktop entry so the GUI can be opened ==="
cat > /home/miyoo/Desktop/antimicrox.desktop <<'EOF'
[Desktop Entry]
Type=Application
Name=AntiMicroX
Comment=Gamepad to mouse/keyboard
Exec=antimicrox
Icon=antimicrox
Terminal=false
Categories=Utility;
EOF
chmod 755 /home/miyoo/Desktop/antimicrox.desktop
chown 1000:1000 /home/miyoo/Desktop/antimicrox.desktop

echo
echo "=== restart antimicrox (as the desktop user, on :0) ==="
pkill -f antimicrox-logged 2>/dev/null || true
pkill -f 'antimicrox --profile' 2>/dev/null || true
sleep 1
su - miyoo -c "DISPLAY=:0 XAUTHORITY=/home/miyoo/.Xauthority setsid nohup /home/miyoo/.local/bin/antimicrox-logged >/dev/null 2>&1 &" || true
sleep 4
ps ax -o pid,user,args | grep -i antimicro | grep -v grep || echo "NOT RUNNING"
echo
echo "=== antimicrox log ==="
tail -6 /home/miyoo/antimicrox.log 2>/dev/null
