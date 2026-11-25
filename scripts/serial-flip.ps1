param(
    [string]$Port = 'COM19',
    [int]$Baud = 115200
)

$sp = New-Object System.IO.Ports.SerialPort $Port, $Baud
$sp.ReadTimeout = 2000
$sp.WriteTimeout = 3000
$sp.DtrEnable = $true
$sp.RtsEnable = $true
$sp.Open()

function SendRaw([string]$t, [int]$d) { $sp.Write($t); Start-Sleep -Milliseconds $d }
function SendCmd([string]$c, [int]$w = 800) { SendRaw "$c`r" 120; Start-Sleep -Milliseconds $w }

$G = '/sys/kernel/config/usb_gadget/miyoo'

Write-Output "=== 1. teardown stale skeleton ==="
SendCmd "echo '' > $G/UDC 2>/dev/null; rm -f $G/configs/c.1/rndis.usb0 $G/configs/c.1/acm.GS0 $G/os_desc/configs 2>/dev/null" 600
SendCmd "rmdir $G/os_desc/interface.rndis $G/functions/rndis.usb0 $G/functions/acm.GS0 2>/dev/null; rmdir $G/configs/c.1/strings/0x409 $G/configs/c.1 $G/strings/0x409 $G/os_desc $G 2>/dev/null; ls -d $G 2>/dev/null || echo GADGET_GONE" 900

Write-Output "=== 2. stop g_serial coming back ==="
SendCmd "sed -i '/^g_serial\$/d' /etc/modules; grep -c . /etc/modules || echo MODULES_EMPTY" 600
SendCmd "printf 'blacklist g_serial\nblacklist g_ether\nblacklist g_multi\n' > /etc/modprobe.d/miyoo-gadget.conf; cat /etc/modprobe.d/miyoo-gadget.conf | tr '\n' ' '" 600

Write-Output "=== 3. rescue timer (fires in 25s if usb0 is missing) ==="
SendCmd "systemd-run --unit=miyoo-gadget-rescue --on-active=25 /bin/sh -c 'sleep 5; if [ ! -d /sys/class/net/usb0 ]; then systemctl stop miyoo-usb-gadget.service; echo \"\" > $G/UDC 2>/dev/null; modprobe g_serial; systemctl restart serial-getty@ttyGS0.service; fi' >/dev/null 2>&1; echo RESCUE_ARMED" 900

Write-Output "=== 4. enable + restart (console will drop here) ==="
SendCmd "systemctl daemon-reload; systemctl enable miyoo-usb-gadget.service 2>&1 | tail -1; systemctl restart miyoo-usb-gadget.service; echo RESTARTED" 1500

Start-Sleep -Milliseconds 1500
$out = $sp.ReadExisting()
$sp.Close()
Write-Output "--- device output ---"
Write-Output (($out -replace "[^\x20-\x7e\r\n]", "") -replace "\[\?2004[hl]", "")
