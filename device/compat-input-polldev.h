/* SPDX-License-Identifier: GPL-2.0 */
/*
 * Minimal stand-in for <linux/input-polldev.h>.
 *
 * Mainline removed input-polldev in 6.14 ("Input: remove input-polldev"), but
 * the ROCKNIX joypad driver still uses it.  Only a fraction of the old API is
 * needed here: allocate a polled input device and drive ->poll() from a delayed
 * work every poll_interval milliseconds.
 *
 * Behavioural note: the original helper called ->open() when userspace opened
 * the input device and ->close() on the last close.  This driver only uses them
 * to latch the initial button state, toggle ->enable and stop rumble, so we call
 * ->open() once at registration and ->close() at unregister, and poll for as
 * long as the device is registered.
 */
#ifndef _ROCKNIX_COMPAT_INPUT_POLLED_DEV_H
#define _ROCKNIX_COMPAT_INPUT_POLLED_DEV_H

#include <linux/device.h>
#include <linux/input.h>
#include <linux/jiffies.h>
#include <linux/slab.h>
#include <linux/workqueue.h>

struct input_polled_dev {
	void *private;
	struct input_dev *input;
	unsigned int poll_interval;	/* milliseconds */
	void (*poll)(struct input_polled_dev *dev);
	void (*open)(struct input_polled_dev *dev);
	void (*close)(struct input_polled_dev *dev);
	struct delayed_work work;
	bool registered;
};

static void __maybe_unused
joypad_compat_poll_work(struct work_struct *work)
{
	struct input_polled_dev *dev =
		container_of(to_delayed_work(work), struct input_polled_dev, work);

	if (dev->poll)
		dev->poll(dev);

	if (READ_ONCE(dev->registered))
		schedule_delayed_work(&dev->work,
				      msecs_to_jiffies(dev->poll_interval ? dev->poll_interval : 10));
}

static struct input_polled_dev *__maybe_unused
__compat_polled_alloc(struct device *parent)
{
	struct input_polled_dev *dev;

	dev = devm_kzalloc(parent, sizeof(*dev), GFP_KERNEL);
	if (!dev)
		return NULL;

	dev->input = devm_input_allocate_device(parent);
	if (!dev->input)
		return NULL;

	dev->poll_interval = 10;
	INIT_DELAYED_WORK(&dev->work, joypad_compat_poll_work);
	return dev;
}

#define devm_input_allocate_polled_device(parent) __compat_polled_alloc(parent)

static int __maybe_unused
input_register_polled_device(struct input_polled_dev *dev)
{
	int err;

	err = input_register_device(dev->input);
	if (err)
		return err;

	WRITE_ONCE(dev->registered, true);

	if (dev->open)
		dev->open(dev);

	schedule_delayed_work(&dev->work,
			      msecs_to_jiffies(dev->poll_interval ? dev->poll_interval : 10));
	return 0;
}

static void __maybe_unused
input_unregister_polled_device(struct input_polled_dev *dev)
{
	WRITE_ONCE(dev->registered, false);
	cancel_delayed_work_sync(&dev->work);

	if (dev->close)
		dev->close(dev);

	input_unregister_device(dev->input);
}

#endif /* _ROCKNIX_COMPAT_INPUT_POLLED_DEV_H */
