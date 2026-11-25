/* SPDX-License-Identifier: GPL-2.0 */
/*
 * Compatibility shim for building the Realtek RTL8733BU driver against
 * kernels that have dropped the classic string helpers.
 *
 * Mainline removed strncpy() once the tree was fully converted to
 * strscpy()/strscpy_pad().  The vendor driver still uses the old name, so
 * restore it with the original semantics -- strncpy() zero-pads the
 * destination when the source is shorter, and a few call sites rely on that
 * (efuse / firmware path buffers), so mapping it to strscpy() would silently
 * change behaviour.
 *
 * Injected via "-include compat.h" from the driver Makefile.
 */
#ifndef _RTL8733BU_COMPAT_H
#define _RTL8733BU_COMPAT_H

#include <linux/kernel.h>
#include <linux/string.h>
#include <linux/types.h>

static inline char *rtl8733bu_strncpy(char *dest, const char *src, size_t count)
{
	size_t i;

	for (i = 0; i < count && src[i] != '\0'; i++)
		dest[i] = src[i];
	for (; i < count; i++)
		dest[i] = '\0';

	return dest;
}

#define strncpy rtl8733bu_strncpy

#endif /* _RTL8733BU_COMPAT_H */
