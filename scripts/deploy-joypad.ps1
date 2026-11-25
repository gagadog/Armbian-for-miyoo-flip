param(
    [string]$HostIp = '192.168.42.1',
    [string]$SshUser = 'miyoo'
)

$root = Split-Path -Parent $PSScriptRoot
$key  = Join-Path $root 'keys\miyoo_debug'
$dtb  = Join-Path $root 'out\rk3566-miyoo-flip-joypad-7.3.dtb'
$ko   = '\\wsl$\Ubuntu-24.04\home\wang\miyoo-build\joypad\drv\rocknix-singleadc-joypad.ko'
$sh   = Join-Path $root 'device\deploy-joypad.sh'

$opts = @('-o','BatchMode=yes','-o','StrictHostKeyChecking=no','-o','UserKnownHostsFile=NUL','-o','IdentitiesOnly=yes')

Write-Output "=== scp DTB ==="
& scp @opts -i $key $dtb "${SshUser}@${HostIp}:/tmp/rk3566-miyoo-flip-joypad.dtb" 2>&1 | Out-Null

Write-Output "=== copy .ko out of WSL ==="
$tmpKo = Join-Path $env:TEMP 'rocknix-singleadc-joypad.ko'
Copy-Item $ko $tmpKo -Force
Write-Output ("  " + (Get-Item $tmpKo).Length + " bytes")

Write-Output "=== scp .ko + script ==="
& scp @opts -i $key $tmpKo "${SshUser}@${HostIp}:/tmp/rocknix-singleadc-joypad.ko" 2>&1 | Out-Null
& scp @opts -i $key $sh   "${SshUser}@${HostIp}:/tmp/deploy-joypad.sh" 2>&1 | Out-Null

Write-Output "=== run ==="
& ssh @opts -i $key "${SshUser}@${HostIp}" "echo miyoo | sudo -S sh /tmp/deploy-joypad.sh" 2>&1
