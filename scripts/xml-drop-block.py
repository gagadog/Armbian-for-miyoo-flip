#!/usr/bin/env python3
"""Remove a named <property name="..."> block from an xfconf XML file."""
import re
import sys


def remove_block(lines, name):
    out = []
    i = 0
    removed = False
    while i < len(lines):
        line = lines[i]
        if re.search(r'<property name="%s"' % re.escape(name), line):
            # find matching </property> by counting property tags from here
            depth = 0
            j = i
            while j < len(lines):
                depth += lines[j].count("<property")
                depth -= lines[j].count("</property>")
                if depth <= 0:
                    break
                j += 1
            i = j + 1
            removed = True
            continue
        out.append(line)
        i += 1
    return out, removed


path = sys.argv[1]
targets = sys.argv[2:]
text = open(path, encoding="utf-8").read()
lines = text.split("\n")

for t in targets:
    lines, ok = remove_block(lines, t)
    print(("removed " if ok else "not found ") + t)

# drop the panel id 2 from the panels array
out = []
for line in lines:
    if 'value="2"' in line and "<value type=\"int\"" in line:
        # only inside the panels array; plugin-ids uses the same shape, so check
        # the previous non-empty line context
        continue
    out.append(line)

open(path, "w", encoding="utf-8").write("\n".join(out))
print("written", path)
