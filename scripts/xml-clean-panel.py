#!/usr/bin/env python3
"""
Clean an xfce4-panel XML:
  * remove the <property name="panel-2" ...> block entirely
  * keep only value 1 inside the top-level "panels" array
  * optionally drop orphaned plugin-N declarations that no panel references
"""
import re
import sys


def block_end(lines, start):
    depth = 0
    j = start
    while j < len(lines):
        depth += lines[j].count("<property")
        depth -= lines[j].count("</property>")
        if depth <= 0:
            return j
        j += 1
    return len(lines) - 1


path = sys.argv[1]
lines = open(path, encoding="utf-8").read().split("\n")

# 1. drop panel-2
out = []
i = 0
while i < len(lines):
    if re.search(r'<property name="panel-2"', lines[i]):
        i = block_end(lines, i) + 1
        print("  removed panel-2")
        continue
    out.append(lines[i])
    i += 1
lines = out

# 2. inside the panels array keep only value 1
out = []
in_panels = False
for line in lines:
    if re.search(r'<property name="panels" type="array">', line):
        in_panels = True
        out.append(line)
        continue
    if in_panels and "</property>" in line:
        in_panels = False
        out.append(line)
        continue
    if in_panels and re.search(r'<value type="int"', line):
        if not re.search(r'value="1"', line):
            print("  panels array: dropped", line.strip())
            continue
    out.append(line)
lines = out

# 3. drop plugin declarations that nothing references
text = "\n".join(lines)
referenced = set(re.findall(r'<value type="int" value="(\d+)"', text))
out = []
i = 0
while i < len(lines):
    m = re.search(r'<property name="plugin-(\d+)" type="string"', lines[i])
    if m and m.group(1) not in referenced:
        i = block_end(lines, i) + 1
        print("  dropped orphan plugin-%s" % m.group(1))
        continue
    out.append(lines[i])
    i += 1
lines = out

open(path, "w", encoding="utf-8").write("\n".join(lines))
print("written", path)
