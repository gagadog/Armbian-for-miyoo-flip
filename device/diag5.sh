#!/bin/sh
export PAN_I_WANT_A_BROKEN_VULKAN_DRIVER=1
echo "=== with PAN_I_WANT_A_BROKEN_VULKAN_DRIVER=1 ==="
vulkaninfo --summary 2>&1 | grep -vE '^\s+VK_[A-Z]' | head -40
echo
echo "=== devices ==="
vulkaninfo --summary 2>&1 | sed -n '/Devices:/,/^$/p' | head -20
