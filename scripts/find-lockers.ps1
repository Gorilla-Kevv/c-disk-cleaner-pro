# scripts/find-lockers.ps1
# Find which running processes/services are likely locking the target cache paths.
$ErrorActionPreference = 'SilentlyContinue'

# EDIT ME: paths you intend to clean, and the apps that usually own them
$targets = @(
  @{ P = 'C:\ProgramData\LGHUB\cache';   App = 'Logitech G HUB (stop service: LGHUBUpdaterService)' },
  @{ P = "$env:APPDATA\Tencent\xwechat"; App = 'WeChat 4.x (Weixin.exe + WeChatAppEx*)' },
  @{ P = "$env:APPDATA\Tencent\WXWork";  App = 'WeCom (WXWork.exe)' },
  @{ P = "$env:LOCALAPPDATA\npm-cache";  App = 'node / IDE terminals' }
)

Write-Output "===== 1. related running processes ====="
$patterns = 'lghub|Weixin|WeChat|WXWork|codex|cherry|opencode|CodeBuddy|workbuddy|node|msedge|chrome'
Get-Process | Where-Object {
  $_.ProcessName -match $patterns -or ($_.Path -and $_.Path -match $patterns)
} | Select-Object ProcessName, Id, @{n='Path';e={if ($_.Path) { $_.Path } else { '(system/elevated)' }}} |
  Format-Table -AutoSize

Write-Output "===== 2. related services ====="
Get-Service -ErrorAction SilentlyContinue | Where-Object { $_.Name -match 'lghub|docker|wsl' } |
  Select-Object Name, Status, StartType | Format-Table -AutoSize

Write-Output "===== 3. leftover assistant cleanup tasks holding handles? ====="
$bg = Get-CimInstance Win32_Process -Filter "Name='powershell.exe' OR Name='pwsh.exe'" |
  Where-Object { $_.CommandLine -match 'clean|disk' }
if ($bg) { $bg | ForEach-Object { Write-Output ("  pid={0}  {1}" -f $_.ProcessId, $_.CommandLine.Substring(0, [Math]::Min(120, $_.CommandLine.Length))) } }
else { Write-Output "  none" }

Write-Output "===== 4. per-target remaining size ====="
foreach ($t in $targets) {
  if (Test-Path -LiteralPath $t.P) {
    $sum = (Get-ChildItem -LiteralPath $t.P -Recurse -File -Force -ErrorAction SilentlyContinue | Measure-Object Length -Sum).Sum
    Write-Output ("  {0,8} GB  {1}   (owner hint: {2})" -f [math]::Round($sum/1GB, 2), $t.P, $t.App)
  } else {
    Write-Output ("     gone        {0}" -f $t.P)
  }
}