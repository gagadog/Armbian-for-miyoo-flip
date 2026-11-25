#!/usr/bin/env python3
"""Audit the Miyoo Flip DTB: gamepad buttons and pinctrl pin collisions."""
import re, sys, collections

DTS = sys.argv[1] if len(sys.argv) > 1 else "/tmp/dec735.dts"

text = open(DTS, encoding="utf-8", errors="replace").read()
lines = text.split("\n")

# ---------------------------------------------------------------- key codes
CODES = {
    0x220: "BTN_DPAD_UP", 0x221: "BTN_DPAD_DOWN", 0x222: "BTN_DPAD_LEFT",
    0x223: "BTN_DPAD_RIGHT", 0x130: "BTN_SOUTH(A)", 0x131: "BTN_EAST(B)",
    0x133: "BTN_NORTH(X)", 0x134: "BTN_WEST(Y)", 0x136: "BTN_TL(L1)",
    0x137: "BTN_TR(R1)", 0x138: "BTN_TL2(L2)", 0x139: "BTN_TR2(R2)",
    0x13a: "BTN_SELECT", 0x13b: "BTN_START", 0x13c: "BTN_MODE",
    0x13d: "BTN_THUMBL", 0x13e: "BTN_THUMBR",
    0x72: "KEY_VOLUMEUP", 0x73: "KEY_VOLUMEDOWN", 0x74: "KEY_POWER",
    0x240: "KEY_UNKNOWN/SW_LID?",
}

# ------------------------------------------------- enumerate gpio-keys nodes
print("=" * 74)
print("GAMEPAD / KEY NODES")
print("=" * 74)
node = None
depth = 0
btn = None
for ln in lines:
    s = ln.strip()
    m = re.match(r'^([A-Za-z0-9_@.\-]+)\s*\{$', s)
    if m:
        node = m.group(1)
        if node in ("gpio-keys", "gpio-keys-volume", "gpio-keys-hall",
                    "gpio-keys-power") or node.startswith("sw"):
            pass
    m2 = re.match(r'^(sw\d+|button\d+|lid)\s*\{$', s)
    if m2:
        btn = {"name": m2.group(1), "gpios": None, "code": None, "label": None}
    if btn is not None:
        g = re.search(r'gpios = <(0x[0-9a-f]+)\s+0x([0-9a-f]+)\s+0x([0-9a-f]+)>', s)
        if g:
            btn["gpios"] = (int(g.group(1), 16), int(g.group(2), 16), int(g.group(3), 16))
        c = re.search(r'linux,code = <0x([0-9a-f]+)>', s)
        if c:
            btn["code"] = int(c.group(1), 16)
        l = re.search(r'label = "([^"]+)"', s)
        if l:
            btn["label"] = l.group(1)
        if s == "};":
            if btn["gpios"]:
                print(f"  {btn['name']:6} {btn['label'] or '':22} "
                      f"gpio bank{btn['gpios'][0]} pin{btn['gpios'][1]:2d} "
                      f"act-low={btn['gpios'][2]==1}  "
                      f"{CODES.get(btn['code'], hex(btn['code']) if btn['code'] else '?')}")
            btn = None

NUM = r'(0x[0-9a-fA-F]+|\d+)'
TUP = re.compile(rf'<{NUM}\s+{NUM}\s+{NUM}\s+0x[0-9a-fA-F]+>')

def tonum(x):
    return int(x, 16) if x.lower().startswith("0x") else int(x)

# ------------------------------------------------------- pinctrl pin usage
# collect: pinctrl node name -> set of (bank,pin)
pins = {}
cur = None
stack = []
for ln in lines:
    s = ln.strip()
    m = re.match(r'^([A-Za-z0-9_@.\-]+)\s*\{$', s)
    if m:
        stack.append(m.group(1))
    if s == "};" and stack:
        stack.pop()
    found = TUP.findall(s)
    if found and stack:
        pins.setdefault(tuple(stack), []).extend(
            [(tonum(a), tonum(b), tonum(c)) for a, b, c in found])

usage = collections.defaultdict(list)
for path, tuples in pins.items():
    for bank, pin, func in tuples:
        usage[(bank, pin)].append("/".join(path[-2:]) + f" f{func}")

print()
print("=" * 74)
print("PINS CLAIMED BY MORE THAN ONE PINCTRL NODE")
print("=" * 74)
dups = {k: v for k, v in usage.items() if len(v) > 1}
if not dups:
    print("  none -- every pin is muxed by exactly one pinctrl group")
else:
    for k in sorted(dups):
        print(f"  bank{k[0]} pin{k[1]:2d}: " + " | ".join(dups[k]))

print()
print("=" * 74)
print("BUTTON PINCTRL GROUPS")
print("=" * 74)
for path, tuples in pins.items():
    if any(x in path for x in ("btn", "hall", "vol")):
        print(f"  {'/'.join(path[-2:])}: " +
              ", ".join(f"b{b}p{p}f{f}" for b, p, f in tuples))
print()
print(f"total pinctrl groups: {len(pins)}   total pin tuples: {sum(len(v) for v in pins.values())}")
