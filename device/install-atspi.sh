#!/bin/sh
set -e
echo "=== install ==="
dpkg -i /tmp/debs/*.deb 2>&1 | tail -12
echo
echo "=== at-spi bus service present? ==="
ls /usr/share/dbus-1/services/ 2>/dev/null | grep -i a11y || echo "  no a11y service file"
dpkg -l python3-pyatspi at-spi2-core libatspi2.0-0t64 2>/dev/null | grep '^ii' | awk '{print "  "$2" "$3}'
echo
echo "=== pyatspi import ==="
python3 -c "import pyatspi; print('pyatspi ok', pyatspi.version) " 2>&1 | head -3
