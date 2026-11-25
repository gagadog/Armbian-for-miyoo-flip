#!/bin/bash
cd /home/wang/miyoo-build/debs
echo "=== packages providing polkit-1-auth-agent ==="
awk '
  /^Package:/ { pkg=$2 }
  /^Provides:/ { if (index($0,"polkit-1-auth-agent")) print "  "pkg"   ("$0")" }
' Packages | sort -u | head -20
