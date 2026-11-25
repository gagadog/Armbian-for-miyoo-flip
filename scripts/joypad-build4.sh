#!/bin/bash
# Final joypad build:
#   * compat shim for input-polldev (removed in 6.14)
#   * joypad_input_g gets a real definition
#   * MODULE_IMPORT_NS("IIO_CONSUMER")
#   * open /dev/ttyS1 from probe instead of a delayed work (kworker root is the
#     initramfs, so filp_open there fails with -ENOENT)
#   * don't re-open the tty from the reader kthread for the same reason
set -e
set -o pipefail
. "$(dirname "$0")/env.sh"
D="$JOYPAD"
S="$ROOT/device"

cp -f "$S/compat-input-polldev.h" "$D/compat-input-polldev.h"
cd "$D"

python3 - <<'PY'
p = "rocknix-singleadc-joypad.c"
s = open(p).read()
orig = s

# --- 1. include the compat header -------------------------------------------
s = s.replace('#include <linux/input-polldev.h>', '#include "compat-input-polldev.h"')

# --- 2. own joypad_input_g --------------------------------------------------
s = s.replace('extern struct input_dev * joypad_input_g;',
              'static struct input_dev *joypad_input_g;')

# --- 3. import the IIO consumer namespace -----------------------------------
if 'MODULE_IMPORT_NS' not in s:
    s = s.replace('MODULE_LICENSE("GPL");',
                  'MODULE_IMPORT_NS("IIO_CONSUMER");\nMODULE_LICENSE("GPL");')

# --- 4. open the tty from probe, not from a delayed work --------------------
old_sched = """		INIT_DELAYED_WORK(&joypad->miyoo_init_work, miyoo_delayed_init_workfn);
		schedule_delayed_work(&joypad->miyoo_init_work, 10 * HZ);"""
new_sched = """		/*
		 * Open ttyS1 right here, in probe context.  The old code
		 * deferred this to a delayed work, but a kworker's root is still
		 * the initramfs, so filp_open("/dev/ttyS1") failed with -ENOENT.
		 */
		miyoo_start_serial(joypad);"""
if old_sched in s:
    s = s.replace(old_sched, new_sched)

# --- 5. never re-open from the reader kthread -------------------------------
old_reopen = """			miyoo_serial_close(joypad);
			if (miyoo_serial_open(joypad) == 0) {
				joypad->last_data_jiffies = jiffies;
				dev_info(joypad->dev, "TTY re-init success!\\n");
			} else {
				dev_err(joypad->dev,
					"Failed to re-open /dev/ttyS1; will retry.\\n");
			}"""
new_reopen = """			/*
			 * Keep the descriptor opened in probe: this is a kthread,
			 * so filp_open() would fail with -ENOENT here too.
			 */
			joypad->last_data_jiffies = jiffies;"""
if old_reopen in s:
    s = s.replace(old_reopen, new_reopen)

# the helper is now unused
s = s.replace('static void miyoo_delayed_init_workfn(struct work_struct *work)',
              'static void __maybe_unused miyoo_delayed_init_workfn(struct work_struct *work)')

if s == orig:
    print("WARNING: no changes applied (already patched?)")
else:
    open(p, "w").write(s)
    print("patched")
PY

grep -n 'compat-input-polldev\|static struct input_dev \*joypad_input_g\|MODULE_IMPORT_NS' rocknix-singleadc-joypad.c
grep -n 'miyoo_start_serial(joypad);' rocknix-singleadc-joypad.c
grep -n 'keeping\|Keep the descriptor\|keep the file' rocknix-singleadc-joypad.c || true

printf 'obj-m := rocknix-singleadc-joypad.o\n' > Makefile

echo "=== refresh config ==="
cd "$K"
make ARCH=arm64 CROSS_COMPILE="$TC" olddefconfig >/dev/null
make ARCH=arm64 CROSS_COMPILE="$TC" -j"$(nproc)" modules_prepare >/dev/null 2>&1 || true
cd "$D"

echo "=== build ==="
make -C "$K" ARCH=arm64 CROSS_COMPILE="$TC" M="$D" KBUILD_MODPOST_WARN=1 modules \
    > /tmp/joy4.log 2>&1 || true
grep -n ' error:' /tmp/joy4.log | head -20 || true
tail -3 /tmp/joy4.log
if [ -f rocknix-singleadc-joypad.ko ]; then
    ls -l rocknix-singleadc-joypad.ko
    python3 -c "
d=open('rocknix-singleadc-joypad.ko','rb').read()
i=d.find(b'vermagic=')
print('vermagic:', d[i:i+120].split(b'\x00')[0].decode())
"
else
    echo NO_KO
fi
