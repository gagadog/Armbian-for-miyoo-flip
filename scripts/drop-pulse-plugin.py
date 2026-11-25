#!/usr/bin/env python3
"""Drop the pulseaudio panel plugin from the xfce4-panel XML.

The plugin crashes xfce4-panel on this image (libs are all present; it dies at
runtime when talking to pipewire-pulse), so volume is provided by desktop icons
and pavucontrol instead.
"""
import re
import sys

path = sys.argv[1]
lines = open(path, encoding="utf-8").read().split("\n")
out = []
removed_decl = removed_id = 0

for line in lines:
    if re.match(r'^ {4}<property name="plugin-12" type="string" value="pulseaudio-plugin"/>$', line):
        removed_decl += 1
        continue
    if re.match(r'^ {8}<value type="int" value="12"/>$', line):
        removed_id += 1
        continue
    out.append(line)

open(path, "w", encoding="utf-8").write("\n".join(out))
print("removed decl:", removed_decl, " removed id:", removed_id)
