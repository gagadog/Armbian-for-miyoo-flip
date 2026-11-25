# Out-of-tree build for the ROCKNIX generic MIPI-DSI panel driver.
#
# On the target device (needs the matching kernel headers):
#   sudo apt install linux-headers-$(uname -r) build-essential
#   make
#   sudo make install
#
# Or cross-build against a kernel tree (see build-module.sh).

obj-m += panel-generic-dsi.o

KDIR ?= /lib/modules/$(shell uname -r)/build

all:
	$(MAKE) -C $(KDIR) M=$(CURDIR) modules

clean:
	$(MAKE) -C $(KDIR) M=$(CURDIR) clean

install:
	$(MAKE) -C $(KDIR) M=$(CURDIR) modules_install
	depmod -a

.PHONY: all clean install
