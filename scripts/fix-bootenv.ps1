$log = 'C:\temp\bootenv.log'
"=== start $(Get-Date) ===" | Out-File $log -Encoding UTF8

# 1. give the boot FAT partition a drive letter again
try {
    Set-Partition -DiskNumber 3 -PartitionNumber 1 -NewDriveLetter F -ErrorAction Stop
    "assigned F:" | Out-File $log -Append -Encoding UTF8
} catch {
    "Set-Partition failed: $($_.Exception.Message)" | Out-File $log -Append -Encoding UTF8
}

$target = 'F:\armbianEnv.txt'
for ($i = 0; $i -lt 20; $i++) {
    if (Test-Path $target) { break }
    Start-Sleep -Milliseconds 300
}

if (-not (Test-Path $target)) {
    "ERROR: $target still missing" | Out-File $log -Append -Encoding UTF8
    exit 1
}

# 2. mask the broken gadget service for the next boot so the legacy g_serial
#    console comes back.  Preserve the original line endings (LF, written from
#    Linux) -- U-Boot's "env import" is happier without stray CRs.
$t = [IO.File]::ReadAllText($target)
"--- before ---" | Out-File $log -Append -Encoding UTF8
$t | Out-File $log -Append -Encoding UTF8

$new = $t -replace 'extraargs=[^\r\n]*',
    'extraargs=cma=256M systemd.mask=miyoo-usb-gadget.service'

[IO.File]::WriteAllText($target, $new)

"--- after ---" | Out-File $log -Append -Encoding UTF8
[IO.File]::ReadAllText($target) | Out-File $log -Append -Encoding UTF8
"=== done ===" | Out-File $log -Append -Encoding UTF8
