#!/bin/sh
echo "=== profile dir ==="
ls -l /home/miyoo/.config/antimicrox/profiles/ /home/miyoo/.local/share/antimicrox/profiles/ 2>/dev/null
echo
echo "=== settings (which profile is active) ==="
cat /home/miyoo/.config/antimicrox/antimicrox_settings.ini 2>/dev/null
echo
echo "=== newest profile content ==="
for f in $(ls -t /home/miyoo/.config/antimicrox/profiles/*.amgp 2>/dev/null | head -2); do
    echo "----- $f -----"
    cat "$f"
    echo
done
