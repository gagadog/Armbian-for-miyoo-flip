#!/bin/sh
set -e
echo "=== install lxpolkit stack ==="
dpkg -i /tmp/nma/lxpolkit_*.deb /tmp/nma/lxsession-data_*.deb 2>&1 | grep -E 'Setting up|error|depends' | head -10
echo
echo "=== configure everything pending ==="
dpkg --configure -a 2>&1 | tail -6
echo
echo "=== package state ==="
dpkg -l network-manager-applet nm-connection-editor lxpolkit lxsession-data 2>/dev/null | grep '^ii' | awk '{print "  "$2" "$3}'
echo
echo "=== autostart entries ==="
ls /etc/xdg/autostart/ | grep -Ei 'nm-applet|lxpolkit' | sed 's/^/  /'
echo
echo "=== any broken packages left? ==="
dpkg -C 2>&1 | head -5 || echo "  none"
