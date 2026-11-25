$log = 'C:\temp\attach.log'
"=== start $(Get-Date) ===" | Out-File $log -Encoding UTF8

"--- disks before ---" | Out-File $log -Append -Encoding UTF8
Get-Disk | Select-Object Number,FriendlyName,BusType,IsOffline,IsReadOnly,OperationalStatus |
    Format-Table -AutoSize | Out-String | Out-File $log -Append -Encoding UTF8

# Windows keeps the FAT volume mounted; take the whole disk offline so the WSL
# HCS layer can attach it exclusively.
try {
    Set-Disk -Number 3 -IsOffline $true -ErrorAction Stop
    "--- disk 3 set offline ---" | Out-File $log -Append -Encoding UTF8
} catch {
    "--- Set-Disk offline failed: $($_.Exception.Message) ---" | Out-File $log -Append -Encoding UTF8
}

Start-Sleep -Seconds 2

# release the volume mount points as well
try { mountvol F: /p 2>&1 | Out-File $log -Append -Encoding UTF8 } catch {}

Start-Sleep -Seconds 1

$out = & wsl.exe --mount '\\.\PHYSICALDRIVE3' --bare 2>&1
"--- wsl --mount rc=$LASTEXITCODE ---" | Out-File $log -Append -Encoding UTF8
$out | Out-String | Out-File $log -Append -Encoding UTF8

Start-Sleep -Seconds 2

"--- disks after ---" | Out-File $log -Append -Encoding UTF8
Get-Disk | Select-Object Number,FriendlyName,IsOffline,OperationalStatus |
    Format-Table -AutoSize | Out-String | Out-File $log -Append -Encoding UTF8

"=== done ===" | Out-File $log -Append -Encoding UTF8
