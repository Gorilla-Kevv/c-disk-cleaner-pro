# scripts/scan.ps1 - read-only disk audit (drives / top dirs / temp / big / old files)
$ErrorActionPreference = 'SilentlyContinue'
$ProgressPreference = 'SilentlyContinue'
function SizeGB($b) { [math]::Round($b / 1GB, 2) }
function DirSize($path) {
  $t = 0; $c = 0
  try { foreach ($f in [System.IO.Directory]::EnumerateFiles($path, '*', 'AllDirectories')) {
      try { $t += ([System.IO.FileInfo]::new($f)).Length; $c++ } catch {} } } catch {}
  return @($t, $c)
}

Write-Output "===== 1. DRIVES ====="
Get-CimInstance Win32_LogicalDisk -Filter "DriveType=3" | ForEach-Object {
  Write-Output ("{0}  Total {1} GB  Free {2} GB" -f $_.DeviceID, (SizeGB $_.Size), (SizeGB $_.FreeSpace))
}

Write-Output ""
Write-Output "===== 2. USER HOME TOP 15 ====="
Get-ChildItem -Path $env:USERPROFILE -Directory -Force | ForEach-Object {
  $r = DirSize $_.FullName
  [PSCustomObject]@{ GB = SizeGB $r[0]; Files = $r[1]; Dir = $_.Name }
} | Sort-Object GB -Descending | Select-Object -First 15 | Format-Table -AutoSize

Write-Output "===== 3. APPDATA TOP 15 ====="
foreach ($base in @($env:APPDATA, $env:LOCALAPPDATA)) {
  Write-Output (">>> " + $base)
  Get-ChildItem -Path $base -Directory -Force | ForEach-Object {
    $r = DirSize $_.FullName
    [PSCustomObject]@{ GB = SizeGB $r[0]; Files = $r[1]; Dir = $_.Name }
  } | Sort-Object GB -Descending | Select-Object -First 15 | Format-Table -AutoSize
}

Write-Output "===== 4. TEMP DIRS ====="
foreach ($p in @($env:TEMP, "$env:LOCALAPPDATA\Temp", 'C:\Windows\Temp') | Select-Object -Unique) {
  if (Test-Path -LiteralPath $p) {
    $r = DirSize $p
    Write-Output ("{0,8} GB  {1,7} files  {2}" -f (SizeGB $r[0]), $r[1], $p)
  }
}

Write-Output ""
Write-Output "===== 5. BIG FILES >400MB (user profile) ====="
Get-ChildItem -Path $env:USERPROFILE -Recurse -File -Force -ErrorAction SilentlyContinue |
  Where-Object { $_.Length -gt 400MB } |
  Sort-Object Length -Descending |
  Select-Object -First 25 @{n='GB';e={SizeGB $_.Length}}, @{n='Modified';e={$_.LastWriteTime.ToString('yyyy-MM-dd')}}, FullName |
  Format-Table -AutoSize

Write-Output ""
Write-Output "===== 6. OLD FILES >180 DAYS ====="
$cut = (Get-Date).AddDays(-180)
foreach ($d in @("$env:USERPROFILE\Desktop", "$env:USERPROFILE\Downloads", "$env:USERPROFILE\Pictures", "$env:USERPROFILE\Videos")) {
  if (Test-Path -LiteralPath $d) {
    $old = Get-ChildItem -Path $d -Recurse -File -Force -ErrorAction SilentlyContinue | Where-Object { $_.LastWriteTime -lt $cut }
    $sum = ($old | Measure-Object Length -Sum).Sum
    Write-Output ("{0}: {1} files, {2} GB" -f $d, $old.Count, (SizeGB $sum))
  }
}

Write-Output ""
Write-Output "NOTE: this scan is strictly read-only. No files were touched."

