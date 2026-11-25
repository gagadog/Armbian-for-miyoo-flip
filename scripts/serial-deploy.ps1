param([string]$Port = 'COM19', [int]$Baud = 115200)

$root = Split-Path -Parent $PSScriptRoot
$gadget = ([IO.File]::ReadAllText((Join-Path $root 'device\miyoo-usb-gadget'))) -replace "`r`n", "`n"
$svc    = ([IO.File]::ReadAllText((Join-Path $root 'device\miyoo-usb-gadget.service'))) -replace "`r`n", "`n"
Write-Output "gadget chars: $($gadget.Length)"

$sp = New-Object System.IO.Ports.SerialPort $Port, $Baud
$sp.Handshake = 'None'
$sp.ReadTimeout = 2000
$sp.WriteTimeout = 4000
$sp.DtrEnable = $true
$sp.RtsEnable = $true
$sp.Open()
Start-Sleep -Milliseconds 500

function Drain { try { return $sp.ReadExisting() } catch { return "" } }
function SendCmd([string]$c, [int]$w = 600) { $sp.Write("$c`r"); Start-Sleep -Milliseconds $w }

# --- log in if we are sitting at a login prompt ---
$banner = Drain
if ($banner -match '(?i)login:') {
    Write-Output "logging in..."
    $sp.Write("root`r"); Start-Sleep -Milliseconds 1200
    $sp.Write("1234`r"); Start-Sleep -Milliseconds 2200
    $null = Drain
}
SendCmd "true" 800
$state = Drain
if ($state -notmatch '#') { Write-Output "WARN: prompt not recognised, continuing anyway" }

function PushFile([string]$content, [string]$remote) {
    $b64 = [Convert]::ToBase64String([Text.Encoding]::UTF8.GetBytes($content))
    SendCmd "rm -f $remote" 200
    $i = 0
    while ($i -lt $b64.Length) {
        $len = [Math]::Min(600, $b64.Length - $i)
        SendCmd "printf '%s' '$($b64.Substring($i,$len))' >> $remote" 80
        $i += $len
    }
    SendCmd "echo PUSHED_$($b64.Length)" 400
}

Write-Output "=== push gadget ==="
PushFile $gadget "/tmp/g.b64"
Write-Output "=== push service ==="
PushFile $svc "/tmp/s.b64"

SendCmd "base64 -d /tmp/g.b64 > /usr/local/sbin/miyoo-usb-gadget && chmod 755 /usr/local/sbin/miyoo-usb-gadget && echo GADGET_WRITTEN" 900
SendCmd "base64 -d /tmp/s.b64 > /etc/systemd/system/miyoo-usb-gadget.service && echo SERVICE_WRITTEN" 600
SendCmd "sh -n /usr/local/sbin/miyoo-usb-gadget && echo SYNTAX_OK" 600
SendCmd "wc -c /usr/local/sbin/miyoo-usb-gadget" 700

Write-Output "=== start supervisor (console will drop) ==="
SendCmd "setsid /usr/local/sbin/miyoo-usb-gadget loop < /dev/null > /var/log/miyoo-gadget.out 2>&1 &" 1500

$out = Drain
try { $sp.Close() } catch {}
Write-Output "--- device output ---"
Write-Output (($out -replace "[^\x20-\x7e\r\n]", "") -replace "\[\?2004[hl]", "")
