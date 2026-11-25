param(
    [string]$HostIp = '192.168.42.1',
    [string]$SshUser = 'miyoo'
)

$root = Split-Path -Parent $PSScriptRoot
$key  = Join-Path $root 'keys\miyoo_debug'
$gadget = Join-Path $root 'device\miyoo-usb-gadget'
$persist = Join-Path $root 'device\persist-gadget.sh'

$opts = @(
    '-o','BatchMode=yes',
    '-o','StrictHostKeyChecking=no',
    '-o','UserKnownHostsFile=NUL',
    '-o','IdentitiesOnly=yes'
)

Write-Output "=== scp supervisor + persist script ==="
& scp @opts -i $key $gadget   "${SshUser}@${HostIp}:/tmp/miyoo-usb-gadget" 2>&1 | Out-Null
& scp @opts -i $key $persist  "${SshUser}@${HostIp}:/tmp/persist-gadget.sh" 2>&1 | Out-Null

Write-Output "=== run persist (sudo) ==="
$remote = 'echo miyoo | sudo -S sh /tmp/persist-gadget.sh 2>&1'
& ssh @opts -i $key "${SshUser}@${HostIp}" $remote 2>&1
