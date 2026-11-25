import io, os, sys

BUILD = os.environ.get("BUILD") or os.path.expanduser("~/miyoo-build")
p = os.path.join(BUILD, "rtl8733bu/tip/os_dep/linux/ioctl_cfg80211.c")
s = open(p, encoding="utf-8", errors="surrogateescape").read()
orig = s

# 1. WIPHY_FLAG_SUPPORTS_5_10_MHZ was removed in 7.x.
s = s.replace(
"""	wiphy->flags |= WIPHY_FLAG_SUPPORTS_5_10_MHZ;""",
"""#if (LINUX_VERSION_CODE < KERNEL_VERSION(7, 0, 0))
	wiphy->flags |= WIPHY_FLAG_SUPPORTS_5_10_MHZ;
#endif""")

# 2. remain_on_channel / cancel_remain_on_channel changed signature in 7.1;
#    not needed for station mode.
s = s.replace(
"""	.remain_on_channel = cfg80211_rtw_remain_on_channel,
	.cancel_remain_on_channel = cfg80211_rtw_cancel_remain_on_channel,""",
"""#if (LINUX_VERSION_CODE < KERNEL_VERSION(7, 1, 0))
	.remain_on_channel = cfg80211_rtw_remain_on_channel,
	.cancel_remain_on_channel = cfg80211_rtw_cancel_remain_on_channel,
#endif""")

# 3. mgmt_tx now returns the cookie instead of writing through u64 *.
#    Only used for AP/P2P/monitor; station mode does not need it.
s = s.replace(
"""#if (LINUX_VERSION_CODE >= KERNEL_VERSION(2, 6, 37)) || defined(COMPAT_KERNEL_RELEASE)
	.mgmt_tx = cfg80211_rtw_mgmt_tx,""",
"""#if (LINUX_VERSION_CODE >= KERNEL_VERSION(2, 6, 37) && LINUX_VERSION_CODE < KERNEL_VERSION(7, 1, 0)) || defined(COMPAT_KERNEL_RELEASE)
	.mgmt_tx = cfg80211_rtw_mgmt_tx,""")

if s == orig:
    print("NO CHANGES APPLIED")
    sys.exit(1)
open(p, "w", encoding="utf-8", errors="surrogateescape").write(s)
print("patched")
