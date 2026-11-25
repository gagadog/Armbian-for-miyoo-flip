param(
    [string]$Port = 'COM19',
    [int]$Baud = 115200
)

# Derive paths from the script location so no non-ASCII literal is needed
# (PowerShell 5.1 reads .ps1 files as ANSI and would mangle them).
$root = Split-Path -Parent $PSScriptRoot

$gadgetPath = Join-Path $root 'device\miyoo-usb-gadget'
$svcPath    = Join-Path $root 'device\miyoo-usb-gadget.service'

$gadget = ([IO.File]::ReadAllText($gadgetPath)) -replace "`r`n", "`n"
$svc    = ([IO.File]::ReadAllText($svcPath))    -replace "`r`n", "`n"

Write-Output "gadget chars: $($gadget.Length)"
Write-Output "service chars: $($svc.Length)"
if ($gadget.Length -lt 500 -or $svc.Length -lt 50) { throw "source files look wrong" }

function ToB64([string]$s) {
    [Convert]::ToBase64String([Text.Encoding]::UTF8.GetBytes($s))
}

$sp = New-Object System.IO.Ports.SerialPort $Port, $Baud
$sp.ReadTimeout = 2000
$sp.WriteTimeout = 3000
$sp.DtrEnable = $true
$sp.RtsEnable = $true
$sp.Open()

function SendRaw([string]$text, [int]$delayMs) { $sp.Write($text); Start-Sleep -Milliseconds $delayMs }
function SendCmd([string]$cmd, [int]$waitMs = 700) { SendRaw "$cmd`r" 120; Start-Sleep -Milliseconds $waitMs }

function PushFile([string]$content, [string]$remoteB64) {
    $b64 = ToB64 $content
    SendCmd "rm -f $remoteB64" 200
    $i = 0; $chunk = 600
    while ($i -lt $b64.Length) {
        $len = [Math]::Min($chunk, $b64.Length - $i)
        $part = $b64.Substring($i, $len)
        SendCmd "printf '%s' '$part' >> $remoteB64" 80
        $i += $len
    }
    SendCmd "echo PUSHED_$($b64.Length)" 400
    return $b64.Length
}

Write-Output "=== gadget -> /tmp/g.b64 ==="
PushFile $gadget "/tmp/g.b64" | Out-Null
Write-Output "=== service -> /tmp/s.b64 ==="
PushFile $svc "/tmp/s.b64" | Out-Null

SendCmd "base64 -d /tmp/g.b64 > /usr/local/sbin/miyoo-usb-gadget && chmod +x /usr/local/sbin/miyoo-usb-gadget && echo GADGET_WRITTEN" 900
SendCmd "base64 -d /tmp/s.b64 > /etc/systemd/system/miyoo-usb-gadget.service && echo SERVICE_WRITTEN" 700
SendCmd "sh -n /usr/local/sbin/miyoo-usb-gadget && echo SYNTAX_OK" 700
SendCmd "wc -c /usr/local/sbin/miyoo-usb-gadget /etc/systemd/system/miyoo-usb-gadget.service" 900

Start-Sleep -Milliseconds 500
$out = $sp.ReadExisting()
$sp.Close()
Write-Output "--- device output ---"
Write-Output (($out -replace "[^\x20-\x7e\r\n]", "") -replace "\[\?2004[hl]", "")
