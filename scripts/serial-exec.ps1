param(
    [string]$Port = 'COM20',
    [int]$Baud = 115200,
    [Parameter(Mandatory=$true)][string]$Cmd,
    [int]$Wait = 3000
)

$sp = New-Object System.IO.Ports.SerialPort $Port, $Baud
$sp.ReadTimeout = 2000
$sp.WriteTimeout = 3000
$sp.DtrEnable = $true
$sp.RtsEnable = $true
$sp.Open()
Start-Sleep -Milliseconds 400

function Drain { try { return $sp.ReadExisting() } catch { return "" } }

$banner = Drain

# log in if a login prompt is showing
if ($banner -match '(?i)login:\s*$' -or $banner -match '(?i)login:') {
    $sp.Write("root`r"); Start-Sleep -Milliseconds 1200
    $sp.Write("1234`r"); Start-Sleep -Milliseconds 2000
    $null = Drain
}

$sp.Write("$Cmd`r")
Start-Sleep -Milliseconds $Wait
$out = ""
for ($i = 0; $i -lt 6; $i++) { $out += Drain; Start-Sleep -Milliseconds 250 }
try { $sp.Close() } catch {}

$clean = ($out -replace "[^\x20-\x7e\r\n]", "") -replace "\[\?2004[hl]", ""
Write-Output $clean
