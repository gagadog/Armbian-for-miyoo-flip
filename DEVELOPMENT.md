# 移植笔记 / 技术细节

> 本文档为中文（English version of the user guide: [README.md](README.md)）。

这份文档记录"为什么这么做"，包括每个模块移植时踩到的坑。想重建或继续改的话看这个。

---

## 为什么选 Armbian 的 `anbernic-rg-ds` 镜像做底

镜像本体是 **Armbian 26.11.2 / Debian trixie / edge 7.3.5**，板级基础选
`anbernic-rg-ds`，唯一原因是 **U-Boot**：

| | U-Boot 配置 |
|---|---|
| ROCKNIX 给 Miyoo Flip V2 用 | `quartz64-a-rk3566_defconfig` |
| Armbian `anbernic-rg-ds` 用 | `quartz64-a-rk3566_defconfig` |
| 该镜像内实测 `u-boot.itb` | 内嵌 `rockchip/rk3566-quartz64-a.dtb`（U-Boot 2026.01） |

Quartz64 A 同样是 RK3566 + RK817 PMIC + SD 卡在 `sdmmc0`，所以引导器不用为 Flip
重编就能读卡拉内核。内核侧完全由我们自己的 DTB 接管。

镜像自带的 `rk3568-anbernic-rg-ds.dtb` 与本项目无关，已在 `armbianEnv.txt` 里换掉。

---

## 树外模块一：面板 `panel-generic-dsi`

FT8006M 640×480，DSI 初始化序列写在 DTB 的 `panel_description` 属性里（60 多条
命令），驱动运行时解析。主线 `panel-simple` 不支持 DT 内嵌初始化序列，所以必须有
这个驱动。

源码来自 ROCKNIX（原本面向 Linux 7.0.2），在 7.3 上有两处 API 变更：

| 7.0 及以前 | 7.3 |
|---|---|
| `drm_panel_init(panel, dev, funcs, type)` | `devm_drm_panel_alloc(dev, type, member, funcs, type)` |
| `of_drm_get_panel_orientation()` | `drm_of_get_panel_orientation()` |

源码里用 `#if LINUX_VERSION_CODE >= KERNEL_VERSION(7, 1, 0)` 做双路兼容。

模块能直接加载的关键：镜像内核**没开 `CONFIG_MODVERSIONS`**、也没开模块签名，
所以只要 vermagic 对上就行。编译时把 `CONFIG_LOCALVERSION` 设成 `-edge-rockchip64`，
产出的 vermagic 与镜像自带模块完全一致：

```
7.3.5-edge-rockchip64 SMP preempt mod_unload aarch64
```

---

## 树外模块二：摇杆 `rocknix-singleadc-joypad`

摇杆不走 ADC，而是通过 **UART1 的 Miyoo 串行协议**（9600 8N1，6 字节帧）与 MCU 通信。
这个驱动同时管 17 个 GPIO 按键和两个摇杆轴，所以它替代了 `gpio-keys`。

移植 7.3 时踩了四个坑：

### 1. `input-polldev` 在 6.14 被主线删除

ROCKNIX 的做法是把这个驱动整套补回内核
（`packages/linux/patches/mainline/0002-input-add-input-polldev-driver.patch`）。
但我们的模块要跑在**原版 Armbian 内核**上，那个内核里没有这些导出符号，加载时会
报未定义。所以写了 `device/compat-input-polldev.h` 做兼容层：

- 提供 `struct input_polled_dev` 和 `devm_input_allocate_polled_device()`
- 用 `delayed_work` 按 `poll_interval` 调 `->poll()`
- 原 API 会在用户打开设备时调 `->open()`；这个驱动只拿它锁存初始按键状态和置
  `enable`，所以改成注册时调一次

### 2. `joypad_input_g` 没有定义

源码里 `extern struct input_dev *joypad_input_g;` 然后直接赋值，全局只有这两处，
定义在另一个模块 `rocknix-joypad.c` 里（那个文件依赖 `input-polldev` 且我们不编译）。
改成 `static struct input_dev *joypad_input_g;`。

### 3. IIO 符号被命名空间挡住

新版内核要求 `MODULE_IMPORT_NS("IIO_CONSUMER")`，否则加载时报：

```
module uses symbol (iio_read_channel_raw) from namespace IIO_CONSUMER, but does not import it
Unknown symbol iio_read_channel_raw (err -22)
```

### 4. `filp_open("/dev/ttyS1")` 在 delayed work 里必然 `-ENOENT`

这是最难查的一个。驱动原本用 `schedule_delayed_work(..., 10*HZ)` 延迟打开串口，
而 delayed work 跑在 kworker 里，**kworker 的 root 还指向 initramfs**，所以
`/dev/ttyS1` 在它的命名空间里根本不存在：

```
Starting /dev/ttyS1 init after driver load.
ERROR: open /dev/ttyS1 failed: -2
```

改成在 probe（`modprobe` 的进程上下文，root 正确）里直接打开，并把读线程里的
"5 秒无数据就重开"逻辑改成只重置超时窗口（线程里重开同样会 ENOENT）。

改完后日志：

```
Opened serial port /dev/ttyS1 and set 9600 8N1 (in-kernel).
Auto-calibration: reading 100 frames...
  Average YL=133, XL=126, YR=112, XR=119
Auto-calibration complete (100 frames).
```

四轴量程 -32760 ~ 32760，死区 4914（DTB 里配）。

---

## 树外模块三：WiFi `8733bu`

RTL8733BU 是 USB WiFi+BT 组合芯片。驱动源码本身已经适配到 7.x，只需要处理三处：

- `strncpy()` 在 7.x 被主线删除 → `module/rtl8733bu-compat.h` 按原语义补回（补零）
- `WIPHY_FLAG_SUPPORTS_5_10_MHZ` 已删除 → 按版本屏蔽
- `remain_on_channel` / `mgmt_tx` 签名在 7.1 变了 → 按版本屏蔽（STA 模式用不到）

**最反直觉的发现：不需要任何外部固件。**

驱动源码里到处是 `FW_NIC.bin`、`AGC_TAB.txt`、`PHY_REG*.txt`、`RadioA-D.txt`，
看着像必须，但把 ROCKNIX/ButterflyOS 的官方镜像扒开看，里面**一个都没有**
（只有 `.ko`）。实际是靠芯片内部固件 + 编译内置的 PHY 表工作，
`request_firmware` 失败后回落到内置表。实测扫描正常，能扫到 9 个 AP。

modprobe 配置沿用 ROCKNIX：

```
options 8733bu rtw_ips_mode=0 rtw_power_mgnt=1 rtw_lps_level=1 rtw_lps_chk_by_tp=1 rtw_enusbss=0
blacklist btusb
softdep btusb pre: 8733bu
```

`blacklist btusb` 是必须的：WiFi 和 BT 在同一个 USB 设备上，udev 同时加载会因
btrtl 下载 BT 固件触发芯片级 reset，把 WiFi 一起干掉。

---

## 用户态：`miyoo-padmouse`

### 为什么不用 antimicrox 的 profile

一开始用的是 antimicrox + 预置 `.amgp`，实测**映射不生效**。原因：

1. 手柄驱动换掉后 SDL GUID 变了（`1900bb07…` → `19009b4d…`），antimicrox 当成新设备
2. 新设备会弹"轴映射向导"，必须**在 GUI 里确认一次**才认 profile
3. 无法在镜像里预置这个确认动作

而且这个板子没有 ID 引脚 / 摇杆是串口协议，antimicrox 的自动识别本来就容易出问题。

所以改成自己写守护进程，直接读 `/dev/input/event*`、写 uinput。好处是行为完全
可测：可以用一个同 GUID 的合成手柄注入事件，观察 uinput 输出。

实测输出（合成手柄推 `ABS_X=30000` + 按 A/B/十字键/START/SELECT/F）：

```
REL X:          2654      ← 指针移动
KEY BTN_LEFT:   1
KEY BTN_RIGHT:  1
KEY UP:         1
KEY ENTER:      1
KEY ESC:        1
KEY LEFTMETA:   1
```

调整手感只需改两个常量：`DEADZONE`（死区）和 `MAX_SPEED`（满推速度）。

### `rgds-pad2key` 要关掉

Armbian 的 RG DS 镜像自带一个 python 守护进程，把整个手柄映射成键盘
（十字键→方向键、A→Enter、B→Esc、F→Alt+Tab…）。它不 grab 设备，所以能和
padmouse 共存，但同一个键会被两边各处理一次。镜像里已 `mask`。

---

## 用户态：`miyoo-lid`

合盖开关是 `gpio-keys-hall` 设备上的 `SW_LID`。logind 默认 `HandleLidSwitch=suspend`，
但这块板子在主线下的 suspend 链路没接好（`rockchip,pm-rk3568` 驱动不存在），
睡下去大概率醒不来。

所以：

- `/etc/systemd/logind.conf.d/miyoo-lid.conf` 把 logind 的合盖行为改成 `ignore`
- `miyoo-lid.service` 监听 `SW_LID`，合盖把背光写 0、开盖恢复原值（直接写 sysfs，
  不依赖 X，控制台也生效）

### 开机黑屏的坑

`systemd-backlight@backlight:backlight.service` 会在**关机时把当前亮度存盘**，
下次开机恢复。如果关机那一刻盖子合着（背光被 `miyoo-lid` 写成了 0），
存下来的就是 0 —— 开机直接黑屏，而且没法从 UI 里救回来。

两道保险：

1. `miyoo-lid` 启动时检查：**盖子开着且背光为 0 → 拉到 max/2**
2. `miyoo-brightness-floor.service`（oneshot，在 backlight restore 之后）：
   背光为 0 就写 120


---

## XFCE 面板：三个典型的坑

任务栏要显示电量 / 音量 / 亮度，涉及的东西比想象中多，都踩过一遍。

### 1. 电源面板插件在单独的包里

`xfce4-power-manager` 本体 **不含** 面板插件，Debian 把它拆成了
`xfce4-power-manager-plugins`。少装它的表现是：面板启动时弹
"无法加载插件"，然后 `xfce4-panel` **直接退出**（不是只少一个图标）。

```bash
$ dpkg -L xfce4-power-manager-plugins | grep '\.so'
/usr/lib/aarch64-linux-gnu/xfce4/panel/plugins/libxfce4powermanager.so
```

注意 `.so` 叫 `libxfce4powermanager.so`，不是 `libpowermanager.so`，
别按名字猜。

### 2. 不要在 root 下用 xfconf-query

`xfconf-query` 需要用户会话的 D-Bus 和 X 授权。用 `sudo` 跑会得到：

```
Failed to init libxfconf: Error spawning dbus-launch --autolaunch=...
```

正确做法是以桌面用户身份、带上会话总线：

```sh
export DISPLAY=:0 XAUTHORITY=$HOME/.Xauthority
export DBUS_SESSION_BUS_ADDRESS=unix:path=/run/user/$(id -u)/bus
```

### 3. 数组属性不能随便 append

两个坑连着踩：

- `xfconf-query -p /panels/panel-1/plugin-ids -a -t int -s 11` —— `-a`
  在这个版本上**替换**数组而不是追加，直接把 plugin-ids 变成 `[11]`，
  面板的所有插件都没了
- `xfconf-query -p /panels -t int -s 1` —— `/panels` 是数组，成员是嵌套的
  `<property name="panel-1">` 子树；这样写会把整个 panel-1 配置**抹掉**

另外残留的第二个面板（`panel-2`）会让同一个插件被实例化两次，表现为
"面板上只显示一部分图标"。

最稳的做法：**直接写 XML 文件**，然后杀掉 `xfconfd` 让它重读：

```sh
pkill -x xfce4-panel; pkill -x xfconfd
cp clean.xml ~/.config/xfce4/xfconf/xfce-perchannel-xml/xfce4-panel.xml
xfce4-panel &
```

⚠️ 顺序很关键：**先停会话再写文件**。`xfconfd` 退出时会把内存里的状态写回 XML，
如果在它活着的时候改文件，会话一重启就会被覆盖回去。

镜像里预置的就是 `device/xfce4-panel.xml`（单面板、11 个插件，11=power-manager）。

### 4. `xfce4-pulseaudio-plugin` 会带崩整个面板

这个官方音量插件在这台机器上表现是：拖一下 → 面板消失。`ldd` 检查没有任何缺失库，
是运行时连 `pipewire-pulse` 出的问题。

处理：直接卸载，改用独立的 `pnmixer`（托盘图标，滚轮调音量）：

```bash
dpkg --purge xfce4-pulseaudio-plugin
apt install pnmixer        # 或者用仓库里的 deb
```

pnmixer 走 ALSA，控制 rk817 的 Master，和 PipeWire 并存没有问题。



## 音频：两个容易漏的点

`CONFIG_SND_SOC_RK817` + `CONFIG_SND_SOC_SIMPLE_CARD` + `CONFIG_SND_SOC_SIMPLE_AMPLIFIER`
都在，DTB 里功放节点也齐全：

```
audio-amplifier { compatible = "simple-audio-amplifier";
                  enable-gpios = <&gpio4 RK_PC2 GPIO_ACTIVE_HIGH>; }
simple-audio-card,aux-devs = <&spk_amp>
```

### 1. `Playback Mux` 默认在耳机

这是最坑的一点。声卡能播放、功放 GPIO 也会被 DAPM 拉高（`gpio-18 ... out hi`），
但扬声器就是没声音，因为 RK817 的输出选择默认是耳机：

```bash
$ amixer -c 1 sget 'Playback Mux'
  Items: 'HP' 'SPK'
  Item0: 'HP'          ← 音频进了耳机通道
```

改成 SPK 并保存：

```bash
amixer -c 1 sset 'Playback Mux' SPK
alsactl store          # 写入 /var/lib/alsa/asound.state
```

镜像里已经带上 `asound.state`，`alsa-restore.service` 开机恢复。

### 2. 功放是 DAPM 控制的，不需要手动拉 GPIO

`simple-audio-amplifier` 会随 "Speaker" 路径自动 enable，播放时
`/sys/kernel/debug/gpio` 里能看到 `gpio-18 (enable) out hi`。

排查顺序建议：先看 `Playback Mux`，再看功放 GPIO，最后才是 I2S/时钟。



## USB：为什么是 NCM 而不是 RNDIS

两个坑，都值得记下来。

### 1. `dr_mode = "otg"` 在这块板子上不起作用

ButterflyOS 原版把下口写成 `dr_mode = "peripheral"`（给他们的 Butterfly Link
USB 传输用），我们想让它既能当 host 又能当 gadget，试了 `"otg"`，结果接 PC 时
PC 只能看到：

```
未知 USB 设备（设备描述符请求失败）   VID_0000&PID_0002
```

原因：这块板子的下口**没有 ID 引脚**，RK356x 的 OTG PHY 把 ID 读成 host，
控制器根本不切角色，一边当 host 一边被 PC 枚举，就成了这个状态。

最终做成两个 DTB 变体：

| 文件 | 下口 `dr_mode` |
|---|---|
| `rk3566-miyoo-flip-joypad.dtb`（默认） | `peripheral` |
| `rk3566-miyoo-flip-usbhost.dtb` | `otg`（host 用） |

用 `/usr/local/sbin/miyoo-usb-role {device|host}` 切换，配合 `armbianEnv.txt` 的
`fdtfile`。

### 2. Windows 11 24H2 移除了 RNDIS 驱动

第一版用 RNDIS，Windows 上卡在：

```
Error  RNDIS  USB\VID_1D6B&PID_0104&MI_02  CM_PROB_FAILED_INSTALL
```

于是换成 **CDC-NCM**（Windows 10 1809+ 原生支持），立刻识别成
`UsbNcm Host Device`。

### 3. legacy `g_serial` 抢 UDC

Armbian 的 RG DS 板级配置会在 `/etc/modules` 里加载 `g_serial`，它用 0525:a4a7
枚举成一个纯串口，把唯一的 UDC 占死，我们的复合 gadget 就绑不上
（插上电脑只会出现"有设备接入"，但永远没有网卡）。

处理：从 `/etc/modules` 删掉，并 `blacklist g_serial`。

### 最终结构

`miyoo-usb-gadget` 是一个常驻轮询的守护进程（不是 oneshot）：

- 插上线 → dwc3 进 peripheral → 出现 UDC → 建 configfs gadget 并绑定
- `usb0` 出现 → 配 `192.168.42.1/24`，重启 dnsmasq
- 复合设备含 **ACM 串口**（`ttyGS*`，救援控制台）+ **NCM 网卡**
- 60 秒内既没有 `usb0` 也没有 `ttyGS*` → 自动解绑并 `modprobe g_serial` 兜底，
  避免把机器变成砖

dnsmasq 只给 PC 发地址（`192.168.42.10-50`），**不设网关和 DNS**，不影响 PC 上网。

---

## 设备树三个变体

| 文件 | 下口 | 输入驱动 | 用途 |
|---|---|---|---|
| `rk3566-miyoo-flip-joypad.dtb` | peripheral | `rocknix-singleadc-joypad` | 默认：摇杆可用 + 连 PC |
| `rk3566-miyoo-flip.dtb` | peripheral | `gpio-keys` | 摇杆模块不可用时的退化版 |
| `rk3566-miyoo-flip-usbhost.dtb` | otg | `gpio-keys` | 下口当 host 用 |

全部由 `src/rk3566-miyoo-flip-armbian.dts` 加 `#define` 派生，避免三份文件各改一遍。

---

## 构建时的两个坑

### 编完 DTB 之后必须重新 `olddefconfig`

`make ARCH=arm64 allnoconfig`（编 DTB 用的最小配置）会把
`include/config/auto.conf` 里的 `CONFIG_MODULES` 抹掉。之后编外部模块会直接报：

```
*** The present kernel disabled CONFIG_MODULES.
```

所以编完模块前一定要：

```bash
cp /boot/config-7.3.5-edge-rockchip64 .config
scripts/config --file .config --set-str LOCALVERSION "-edge-rockchip64"
make ARCH=arm64 olddefconfig
make ARCH=arm64 modules_prepare
```

### `KBUILD_MODPOST_WARN=1` 是必须的

没有完整内核的 `Module.symvers` 时 modpost 会报一堆未定义符号，但这个内核关了
MODVERSIONS，符号运行时由 vmlinux 解析，不影响加载。不加这个参数 modpost 会
直接失败。

---

## 脚本索引

| 脚本 | 作用 |
|---|---|
| `scripts/env.sh` | 所有脚本共用的路径（`ROOT` / `BUILD` / 内核树 / 工具链） |
| `scripts/dl.sh` | 下载内核源码 + Armbian 镜像 |
| `scripts/grow.sh` | 根分区扩到 5 GiB 并 resize2fs |
| `scripts/build-all.sh` | 编 3 个 DTB 变体 |
| `scripts/mod735b.sh` | 编面板模块（含 vermagic 校验） |
| `scripts/joypad-build4.sh` | 编摇杆模块（含全部 4 处适配） |
| `scripts/patch-wifi.py` | WiFi 驱动的 7.3 API 补丁 |
| `scripts/fold-v7.sh` | 把所有改动打进镜像并打包 |
| `scripts/verify-v7.sh` | 反查镜像内容 |
| `device/miyoo-padmouse.py` | 摇杆/按键 → 鼠标键盘 |
| `device/miyoo-lid.py` | 合盖关背光 |
| `device/miyoo-usb-gadget` | ACM+NCM 复合 gadget |
| `scripts/pad-audit.py` | 解析 DTB 检查按键引脚与复用冲突 |

---

## 从源码重建

需要 Linux 主机、`aarch64-none-linux-gnu-` 工具链、约 30 GB 磁盘。

```bash
scripts/dl.sh            # 下载内核 7.3.5 + Armbian 底包镜像
scripts/grow.sh          # 根分区扩到 5 GiB
scripts/build-all.sh     # 编 3 个 DTB 变体
scripts/mod735b.sh       # 编面板模块
scripts/joypad-build4.sh # 编摇杆模块（含全部 7.3 适配补丁）
scripts/fold-v7.sh       # 把所有改动打进镜像并打包
```

所有脚本的路径集中在 `scripts/env.sh`：

- `ROOT` = 本仓库根目录（默认自动取 `scripts/` 的上一级）
- `BUILD` = 构建工作区，默认 `$HOME/miyoo-build`，里面有
  `src/linux-7.3.5`、`img/`、`debs/`、`joypad/drv`、`rtl8733bu/tip`

换机器只改这一处，或用环境变量覆盖：

```bash
BUILD=/data/build scripts/fold-v7.sh
```

`scripts/` 下其余文件是移植期间的一次性探查脚本（读寄存器、抓 dmesg、
试挂载等），保留是为了可追溯，不保证在别的机器上能直接跑。

---

## 发布前需要处理

- **调试用 SSH 公钥**：v7 起镜像里已**不含**任何 `authorized_keys`
  （`/home/miyoo/.ssh` 和 `/root/.ssh` 都删掉了）。如果你需要远程调试，
  自己往里放公钥即可。
- 内核模块以 GPL-2.0 分发，源码和构建脚本必须随镜像提供 —— 本仓库已包含
  `device/`、`src/`、`scripts/`，满足要求。

---

## 已知问题 / TODO

- **蓝牙**：需要 btrtl 补丁（ROCKNIX 的
  `0005-Bluetooth-btrtl-Add-the-support-for-RTL8733BU.patch`）+ BT 固件，
  且要处理与 WiFi 共用 USB 设备的 reset 冲突
- **Vulkan**：PanVK 只有 1.0 且 Mesa 标注不合规。要用 DXVK 只能走 Arm 闭源
  Mali 路线（移植 kbase 内核模块到 7.3）
- **深度睡眠**：缺 `rockchip,pm-rk3568`，需要补驱动或改用其他 suspend 方案
- **SPI NAND**：内核未启用 `CONFIG_MTD_SPI_NAND`，读不到片上存储

---

## 许可与致谢

本镜像聚合了多个开源项目，按各自许可证分发：

| 组件 | 来源 | 许可 |
|---|---|---|
| 基础镜像 | [Armbian](https://www.armbian.com/) | GPL-2.0 |
| 内核 | Linux 7.3.5 | GPL-2.0 |
| `panel-generic-dsi` | [ROCKNIX](https://github.com/ROCKNIX/distribution) | GPL-2.0 |
| `rocknix-singleadc-joypad` | [ROCKNIX](https://github.com/ROCKNIX/distribution) | GPL-2.0 |
| `8733bu` Wi-Fi 驱动 | [Awesome-Embedded-Learning-Studio](https://github.com/Awesome-Embedded-Learning-Studio/rtl8733bu-linux-driver) | GPL-2.0 |
| 设备树参考 | [butterflyOS](https://github.com/KeatenPerkins/butterflyOS) | GPL-2.0 / MIT |
| 引导器 | [GammaOS Core](https://github.com/TheGammaSqueeze/GammaOSCore) | 见上游 |

特别感谢：

- **ROCKNIX / butterflyOS** —— 摇杆驱动、面板驱动、设备树的绝大部分工作
- **司徒（steward-fu）** —— 厂商 DTS、引脚与寄存器参考值
- **TheGammaSqueeze** —— Gamma 引导器，让 SD 卡启动成为可能
- **Armbian** —— RK3568/RK3566 镜像与 U-Boot 支持
