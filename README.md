# Miyoo Flip · Armbian + XFCE

An Armbian image for the **Miyoo Flip** (Rockchip RK3566) that boots straight to
an XFCE desktop: display, buttons, sticks, Wi-Fi, audio and HDMI all work.

**中文: [README.zh-CN.md](README.zh-CN.md)** · Porting notes (Chinese):
[DEVELOPMENT.md](DEVELOPMENT.md)

---

## Image

| | |
|---|---|
| File | `Armbian-MiyooFlip_26.11.2_trixie_edge_7.3.5_xfce_v7.img.xz` |
| Compressed / unpacked | 766 MiB / 6.02 GiB (rootfs grows to fill the card on first boot) |
| SHA-256 | `2c158e9e5dff045d5bfeff6e5b50ce1cd72f1b39969196a1b422dfca46260d4e` |

```bash
xz -dc Armbian-MiyooFlip_26.11.2_trixie_edge_7.3.5_xfce_v7.img.xz \
  | sudo dd of=/dev/sdX bs=4M status=progress conv=fsync
```

On Windows use balenaEtcher or Rufus — both write `.img.xz` directly.

### Before flashing: install the Gamma loader

The stock preloader lives in SPI NAND and only looks for U-Boot there, never on a
microSD card. Install the Gamma dual-boot loader once first:

1. Download `GammaLoaderMiyooFlip.zip`:
   <https://github.com/TheGammaSqueeze/GammaOSCore/releases/tag/beta2.5_miyooflip>
   (the assets are password protected; the password is in that page's release notes)
2. Extract it to the root of a FAT32 card, insert it into the **left** slot and
   boot the stock firmware
3. **Apps → Gamma Bootloader Installer** — it reboots a few times and lands back
   in the Miyoo menu
4. Write this image to another card, insert it into the **right** slot and boot

Back up the SPI NAND first. Unbricking:
<https://github.com/spruceUI/spruceOS/wiki/16.-Miyoo-Flip-Unbricking>

### Accounts

| User | Password | Notes |
|---|---|---|
| `miyoo` | `miyoo` | sudo, auto-login to XFCE |
| `root` | `1234` | serial / tty |

---

## What works

| Feature | Status | Notes |
|---|---|---|
| Display | ✅ | 640×480 MIPI-DSI |
| Backlight | ✅ | slider / `brightnessctl` / desktop buttons |
| Buttons | ✅ | 17 keys |
| Analog sticks | ✅ | both, with mouse emulation |
| Rumble | ✅ | driven by the joypad driver |
| Wi-Fi | ✅ | scan, connect, tray icon |
| Audio | ✅ | speaker + headphone detection |
| Battery / charging | ✅ | panel battery icon |
| HDMI | ✅ | video + audio |
| Dual SD slots | ✅ | boot slot + second slot |
| GPU | ✅ | Panfrost, OpenGL 3.1 |
| Bluetooth | ❌ | shares the Wi-Fi chip, not ported |
| Vulkan | ⚠️ | PanVK is 1.0 only, no DXVK |
| Suspend | ❌ | no suspend driver; lid only blanks the panel |

System: Debian 13 · kernel 7.3.5 · XFCE 4.20

---

## Controls

`miyoo-padmouse` maps the gamepad to mouse + keyboard:

| Input | Action |
|---|---|
| Left stick | Pointer |
| Right stick | Scroll |
| A / B | Left / right click |
| X / Y | Esc / Enter |
| D-pad | Arrow keys |
| START / SELECT | Enter / Esc |
| L1 / R1 | PageUp / PageDown |
| L2 / R2 | Backspace / Delete |
| L3 / R3 | Space / Tab |
| F (HOME) | Super (application menu) |

- **Lid**: closing turns the backlight off, opening restores it. No suspend.
- **Brightness**: the slider in the panel's battery icon, or `brightnessctl set 20%`;
  there are also "Brightness ±" desktop icons
- **Volume**: `pnmixer` tray icon (scroll to adjust), plus "Volume ±" desktop icons
- **On-screen keyboard**: `onboard`, auto-starts at the bottom of the screen
- **Wi-Fi**: `nm-applet` tray icon, or

  ```bash
  nmcli device wifi list
  nmcli device wifi connect "SSID" password "password"
  ```
- **Custom mappings**: `antimicrox` is installed; run
  `sudo systemctl stop miyoo-padmouse` first or buttons fire twice
- **Bottom port as USB host**: `sudo miyoo-usb-role host` then reboot; switch back
  with `device`

---

## I/O

| Function | Interface / pin | Notes |
|---|---|---|
| Panel | MIPI-DSI0 + D-PHY0 | reset GPIO4_A0 |
| Backlight | PWM4 | 800 Hz (period 1250000 ns) |
| Sticks | UART1 (`uart1m0`) | 9600 8N1, `/dev/ttyS1` |
| Rumble | PWM5 | |
| D-pad | GPIO3_A3 / A4 / A5 / A6 | up / down / left / right |
| A / B / X / Y | GPIO3_C2 / C3 / C1 / C0 | |
| SELECT / START | GPIO3_B6 / B5 | |
| F (HOME) | GPIO3_A1 | `BTN_MODE` |
| L1 / R1 | GPIO3_B1 / B3 | |
| L2 / R2 | GPIO3_B2 / B4 | |
| L3 / R3 | GPIO2_C1 / C0 | active high |
| Volume keys | GPIO3_A7 (+) / B0 (−) | |
| Lid hall sensor | GPIO0_C6 | `SW_LID` |
| LEDs | GPIO0_B4 (green) / GPIO0_C2 (status, charging) | |
| Speaker amp | enable GPIO4_C2 | RK817 codec, I2S1 |
| Headphone detect | GPIO4_C6 | |
| HDMI | HDMI + I2S0 | video + audio |
| Bottom USB-C | `usb_host0_xhci` @fcc00000 (USB2) | peripheral by default (USB NIC + serial) |
| Top USB-C | `usb_host0_ehci/ohci` @fd800000 | host only, VBUS enable GPIO4_C5 |
| Wi-Fi chip | RTL8733BU on `usb_host1_ehci` @fd880000 | rail `vcc_wifi` |
| SD slots | right `sdmmc0` (boot) / left `sdmmc1` | left slot power enable GPIO2_B1 |
| Debug UART | UART2, 1.5 Mbaud | `ttyS2` |
| PMIC | RK817 @I2C0 0x20 + RK8600 @0x40 | |
