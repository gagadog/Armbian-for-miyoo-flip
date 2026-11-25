#!/bin/bash
F=/tmp/dec735.dts
echo "=== dsi node tree ==="
grep -n 'dsi@fe060000\|panel@0\|mipi-dphy@fe850000\|dsi_dphy\|video-phy' "$F" | head -10
echo
echo "=== dsi node block (status/ports) ==="
awk '/dsi@fe060000 \{/{f=1} f{print NR": "$0} f&&/^\t\};/{exit}' "$F" | grep -E 'status|compatible|clock|phy|port|reg =' | head -14
echo
echo "=== dphy status ==="
awk '/mipi-dphy@fe850000 \{/{f=1} f{print} f&&/^\t\};/{exit}' "$F" | grep -E 'status|compatible|clock' | head
