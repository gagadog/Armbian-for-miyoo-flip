#!/usr/bin/env python3
"""
Produce a clean single-panel xfce4-panel.xml from the captured two-panel one.

Uses indentation-aware block removal because the file is consistently indented:
  indent 4 : panel-N / plugin-N property blocks (and panels-array <value> lines)
  indent 8 : plugin-ids <value> lines inside panel-1
"""
import re
import sys

src, dst = sys.argv[1], sys.argv[2]
lines = open(src, encoding="utf-8").read().split("\n")


def indent_of(line):
    return len(line) - len(line.lstrip(" "))


def drop_block(lines, name):
    out, i = [], 0
    while i < len(lines):
        if re.search(r'<property name="%s"' % re.escape(name), lines[i]):
            ind = indent_of(lines[i])
            close = ' ' * ind + "</property>"
            j = i + 1
            while j < len(lines) and lines[j] != close:
                j += 1
            print("  dropped %s (%d lines)" % (name, j - i + 1))
            i = j + 1
            continue
        out.append(lines[i])
        i += 1
    return out


# 1. panel-2 and its plugins 13..18
for name in ["panel-2"] + ["plugin-%d" % n for n in range(13, 40)]:
    lines = drop_block(lines, name)

# 2. remove the "2" from the panels array (indent 4, not the indent-8 plugin ids)
out = []
for line in lines:
    if re.fullmatch(r' {4}<value type="int" value="2"/>', line):
        print("  dropped panels-array entry 2")
        continue
    out.append(line)
lines = out

open(dst, "w", encoding="utf-8").write("\n".join(lines))

# report
text = "\n".join(lines)
print("  panels:", re.findall(r'name="(panel-\d+)" type="empty"', text))
ids = re.findall(r'<value type="int" value="(\d+)"/>', text)
print("  all int values:", ids)
print("  plugin decls:", re.findall(r'name="(plugin-\d+)" type="string"', text))
