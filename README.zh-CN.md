# Miyoo Flip · Armbian + XFCE

Miyoo Flip（RK3566）的 Armbian 镜像，开机直接进 XFCE 桌面：屏幕、按键、摇杆、Wi-Fi、
声音、HDMI 都可用。

**English: [README.md](README.md)** · 移植细节：[DEVELOPMENT.md](DEVELOPMENT.md)

---

## ⚠️ 已知问题：息屏 / 合盖后出现残影、泛白

合盖（背光关闭）或长时间息屏后，屏幕可能留下上一幅画面的残影，整体发白、泛白。
放一段时间、或点亮后显示一会儿动态内容，会自行恢复。

原因目前未确认：合盖只关背光，面板本身仍在持续扫描同一帧，长时间静态画面容易产生
影像残留；也可能与背光断电方式导致的液晶偏置有关。**是否会对面板造成永久损伤尚不
确定**。如果在意，尽量不要让设备长时间处于合盖 / 息屏状态存放；需要长时间放置时，
可以让屏幕保持点亮停在会变化的画面上。

---

## 镜像

| | |
|---|---|
| 文件 | `Armbian-MiyooFlip_26.11.2_trixie_edge_7.3.5_xfce_v7.img.xz` |
| 压缩 / 解压 | 766 MiB / 6.02 GiB（分区首次启动自动扩到整卡） |
| SHA-256 | `2c158e9e5dff045d5bfeff6e5b50ce1cd72f1b39969196a1b422dfca46260d4e` |

```bash
xz -dc Armbian-MiyooFlip_26.11.2_trixie_edge_7.3.5_xfce_v7.img.xz \
  | sudo dd of=/dev/sdX bs=4M status=progress conv=fsync
```

Windows 用 balenaEtcher 或 Rufus，可直接写 `.img.xz`。

### 刷之前：先装 Gamma 引导器

原厂 preloader 在 SPI NAND 上，只从 NAND 找 U-Boot，不认 SD 卡。所以要先装一次
Gamma 双启动引导器：

1. 下载 `GammaLoaderMiyooFlip.zip`：
   <https://github.com/TheGammaSqueeze/GammaOSCore/releases/tag/beta2.5_miyooflip>
   （资源有密码，密码写在该页 release notes 里）
2. 解压到 FAT32 卡的根目录，插**左侧**卡槽，开机进原厂系统
3. **Apps → Gamma Bootloader Installer**，等它自动重启几次回到 Miyoo 菜单
4. 把本镜像烧到另一张卡，插**右侧**卡槽开机

先备份 SPI NAND。救砖教程：<https://github.com/spruceUI/spruceOS/wiki/16.-Miyoo-Flip-Unbricking>

### 账号

| 用户 | 密码 | 说明 |
|---|---|---|
| `miyoo` | `miyoo` | 有 sudo，开机自动登录桌面 |
| `root` | `1234` | 串口 / tty |

---

## 可工作的部分

| 功能 | 状态 | 说明 |
|---|---|---|
| 显示 | ✅ | 640×480 MIPI-DSI |
| 背光 | ✅ | 滑条 / `brightnessctl` / 桌面按钮 |
| 按键 | ✅ | 17 键 |
| 摇杆 | ✅ | 双摇杆，可模拟鼠标 |
| 振动 | ✅ | 摇杆驱动控制 |
| Wi-Fi | ✅ | 扫描、连接、托盘图标 |
| 声音 | ✅ | 扬声器 + 耳机检测 |
| 电量 / 充电 | ✅ | 面板电量图标 |
| HDMI | ✅ | 画面 + 声音 |
| 双 SD 卡槽 | ✅ | 启动槽 + 第二槽 |
| GPU | ✅ | Panfrost，OpenGL 3.1 |
| 蓝牙 | ❌ | 与 Wi-Fi 同一芯片，未适配 |
| Vulkan | ⚠️ | PanVK 仅 1.0，DXVK 跑不了 |
| 休眠 | ❌ | 无 suspend 驱动，合盖只关背光 |

系统：Debian 13 · 内核 7.3.5 · XFCE 4.20

---

## 操作方式

`miyoo-padmouse` 把手柄映射成鼠标键盘：

| 输入 | 动作 |
|---|---|
| 左摇杆 | 鼠标指针 |
| 右摇杆 | 滚动 |
| A / B | 左键 / 右键 |
| X / Y | Esc / Enter |
| 十字键 | 方向键 |
| START / SELECT | Enter / Esc |
| L1 / R1 | PageUp / PageDown |
| L2 / R2 | Backspace / Delete |
| L3 / R3 | Space / Tab |
| F（HOME） | Super（应用菜单） |

- **合盖**：关背光，开盖恢复原亮度，不休眠
- **亮度**：点面板电池图标里的滑条，或 `brightnessctl set 20%`；桌面也有「亮度 ±」图标
- **音量**：托盘 `pnmixer` 图标（滚轮调），或桌面「音量 ±」图标
- **屏幕键盘**：`onboard`，开机自启在屏幕下方
- **Wi-Fi**：托盘 `nm-applet` 图标连网，或

  ```bash
  nmcli device wifi list
  nmcli device wifi connect "SSID" password "密码"
  ```
- **自定义手柄映射**：`antimicrox` 已装，先 `sudo systemctl stop miyoo-padmouse`，否则同一个键会触发两次
- **下口当 USB host**：`sudo miyoo-usb-role host` 后重启，切回用 `device`

---

## IO 口

| 功能 | 接口 / 引脚 | 备注 |
|---|---|---|
| 屏幕 | MIPI-DSI0 + D-PHY0 | 复位 GPIO4_A0 |
| 背光 | PWM4 | 800 Hz（周期 1250000 ns） |
| 摇杆 | UART1（`uart1m0`） | 9600 8N1，`/dev/ttyS1` |
| 振动马达 | PWM5 | |
| 十字键 | GPIO3_A3 / A4 / A5 / A6 | 上 / 下 / 左 / 右 |
| A / B / X / Y | GPIO3_C2 / C3 / C1 / C0 | |
| SELECT / START | GPIO3_B6 / B5 | |
| F（HOME） | GPIO3_A1 | `BTN_MODE` |
| L1 / R1 | GPIO3_B1 / B3 | |
| L2 / R2 | GPIO3_B2 / B4 | |
| L3 / R3 | GPIO2_C1 / C0 | 高有效 |
| 音量键 | GPIO3_A7（+）/ B0（−） | |
| 合盖霍尔 | GPIO0_C6 | `SW_LID` |
| LED | GPIO0_B4（绿）/ GPIO0_C2（状态、充电） | |
| 扬声器功放 | 使能 GPIO4_C2 | RK817 codec，I2S1 |
| 耳机检测 | GPIO4_C6 | |
| HDMI | HDMI + I2S0 | 画面 + 声音 |
| USB 下口 | `usb_host0_xhci` @fcc00000（USB2） | 默认 peripheral（USB 网卡 + 串口） |
| USB 上口 | `usb_host0_ehci/ohci` @fd800000 | 纯 host，VBUS 使能 GPIO4_C5 |
| Wi-Fi 芯片 | RTL8733BU，`usb_host1_ehci` @fd880000 | 供电 `vcc_wifi` |
| SD 卡槽 | 右槽 `sdmmc0`（启动）/ 左槽 `sdmmc1` | 左槽电源使能 GPIO2_B1 |
| 调试串口 | UART2，1.5 Mbaud | `ttyS2` |
| 电源管理 | RK817 @I2C0 0x20 + RK8600 @0x40 | |
