param([string]$Port = 'COM19', [int]$Baud = 115200)

$sp = New-Object System.IO.Ports.SerialPort $Port, $Baud
$sp.ReadTimeout = 1500
$sp.WriteTimeout = 2000
$sp.DtrEnable = $true
$sp.RtsEnable = $true
$sp.Open()
Start-Sleep -Milliseconds 300
$sp.DiscardInBuffer()
$sp.Write("setsid /usr/local/sbin/miyoo-usb-gadget loop < /dev/null > /var/log/miyoo-gadget.out 2>&1 &`r")
Start-Sleep -Milliseconds 1200
try { $sp.Write("echo LAUNCHED`r") } catch {}
Start-Sleep -Milliseconds 800
try { $out = $sp.ReadExisting() } catch { $out = "" }
try { $sp.Close() } catch {}
Write-Output (($out -replace "[^\x20-\x7e\r\n]", "") -replace "\[\?2004[hl]", "")
