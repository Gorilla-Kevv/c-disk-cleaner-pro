# Cache Locations — Windows 常见缓存/数据/锁定源知识库

> 覆盖常见类别：开发工具链、IM/办公应用、外设厂商套件、浏览器与系统组件。未列出的应用用文末「通用探测方法论」自行定位。

## 开发工具链（绿区，可再生）

| 缓存 | 路径 | 建议动作 | 迁移变量 |
|---|---|---|---|
| pip | `%LOCALAPPDATA%\pip\cache` | 清或迁 | `PIP_CACHE_DIR` |
| npm | `%LOCALAPPDATA%\npm-cache` | 清或迁（官方 `npm cache clean --force`） | `NPM_CONFIG_CACHE` |
| uv | `%LOCALAPPDATA%\uv\cache` | 清或迁 | `UV_CACHE_DIR` |
| HuggingFace | `~\.cache\huggingface\hub` | 迁 | `HF_HOME`（根）+ `HF_HUB_CACHE`（hub） |
| PyTorch hub | `~\.cache\torch` | 迁 | `TORCH_HOME` |
| ModelScope | `~\.cache\modelscope` | 迁 | `MODELSCOPE_CACHE` |
| Gradle | `GRADLE_USER_HOME`（默认 `~\.gradle`） | 迁（含 wrapper 发行版，勿只迁 caches） | `GRADLE_USER_HOME` |
| 鸿蒙 hvigor | `~\.hvigor\project_caches` | 清（构建缓存，可达数十万文件） | — |
| JetBrains | `%LOCALAPPDATA%\JetBrains\<IDE>\{index,log,caches,jcef_cache}` | 清（索引重建） | — |
| VS Code | `%APPDATA%\Code\{CachedExtensionVSIXs,CachedData,Cache,logs}` | 清 | — |
| C++ 扩展 | `%LOCALAPPDATA%\Microsoft\vscode-cpptools` | 清 | — |
| NVIDIA DXCache | `%LOCALAPPDATA%\NVIDIA\DXCache` | 清（shader 缓存自动重建） | — |
| Chromium 快照 | `~\.chromium-browser-snapshots` | 清 | — |
| codex 运行时 | `~\.cache\codex-runtimes` | 清 | — |

## IM / 办公应用（数据位置需读配置确认）

| 应用 | 程序数据 | 聊天/文件数据 | 锁定者 | 备注 |
|---|---|---|---|---|
| 微信 4.x | `%APPDATA%\Tencent\xwechat`（update/log/radium/XPlugin） | config `*.ini` 里一行路径 | Weixin.exe + 大量 WeChatAppEx 子进程 | update 会反复累积；radium/XPlugin 删后重下 |
| QQ NT | `%APPDATA%\Tencent\QQNT` | 默认 `%USERPROFILE%\Documents\Tencent Files`，可自定义为任意盘 | QQ.exe | 聊天文件大头通常在自定义盘 |
| 企业微信 | `%APPDATA%\Tencent\WXWork`（cef/wmpf 小程序） | `%USERPROFILE%\Documents\WXWork`（qtCef 是 CEF 缓存可清） | WXWork.exe | 文件位置应用内可改 |
| 腾讯会议 | `%APPDATA%\Tencent\WeMeet\Global` | — | wemeetapp.exe | — |

> 通用规律：聊天/文件数据的位置一定写在应用配置里（ini/json/注册表），先读配置再决定"清缓存"还是"迁数据"，不要靠猜。

## 硬件/系统应用

| 应用 | 缓存 | 锁定者 | 处理 |
|---|---|---|---|
| 罗技 G HUB | `C:\ProgramData\LGHUB\cache`（更新下载缓存，可达数 GB） | lghub_agent + **LGHUBUpdaterService（服务）** | 提权停服务→清→启服务→重启 lghub.exe |
| 罗技 depots | `C:\ProgramData\LGHUB\depots` | 同上 | 删后自动重下 |
| Edge/Chrome | `...\User Data\Default\{Cache,Code Cache,GPUCache}` | 多进程 | 逐文件清可清大部分 |
| 缩略图 | `%LOCALAPPDATA%\Microsoft\Windows\Explorer\thumbcache_*.db` | explorer.exe | 停 explorer 再删（可选） |
| 系统临时 | `%LOCALAPPDATA%\Temp` | 各种运行中程序 | 能清多少清多少，重启后再清一次 |
| Windows 更新 | `C:\Windows\SoftwareDistribution\Download` | wuauserv | 磁盘清理工具处理 |

## AI 编码助手 / Agent CLI（新型大户，模式通用）

各类 AI 编码助手（CLI 或桌面版）的数据目录几乎都遵循同一模式：`~\.<app>` 或 `~\.config\<app>`，内含可安全清理的缓存子目录。

| 可清子目录（命名模式） | 说明 |
|---|---|
| `tmp` / `.tmp` / `cache` / `hub_*cache` | 临时与缓存，直接清 |
| `logs` / `traces` / `diagnostics` / `pending-telemetry` | 日志遥测，常被后台进程锁定，需先退出应用 |
| `binaries` / `runtimes` / `*updater*` | 运行时与更新包，删后自动重下 |
| `plugins\cache`、`*marketplace.staging-*` | 插件/市场缓存；staging-* 是更新失败残留 |
| `sessions` / `history` / `memory` / `workspace` | 🟡 会话与记忆数据，删前必须确认 |
| `skills` / `extensions` / `plugins` 本体 | 🟡 重下成本高，先确认是否还有该工具在用 |

模式要点：
- 桌面版 AI 助手的更新安装包常堆在 `%LOCALAPPDATA%\<app>-updater` 或 `@<app>-updater`（单个可达 0.5 GB）
- 带 `staging-<数字>-<时间戳>` 后缀的目录是市场/更新失败残留，可清
- ⚠️ 用户自建的共享资源目录（如集中管理的技能库、模型库）永远标红；若要把多个工具指向同一目录，用 `mklink /J` junction，并先关闭该工具的云同步功能，否则会被重建覆盖

## 通用探测方法论（定位任意应用的缓存）

对知识库未覆盖的应用，按以下顺序定位：

1. **进程倒查**：运行该应用，`Get-Process | Where-Object { $_.Path -match '<厂商或应用名>' }` 拿到安装目录
2. **数据目录扫描**：在 `%APPDATA%`、`%LOCALAPPDATA%`、`%PROGRAMDATA%`、`~` 下按厂商名/应用名模糊匹配目录，逐个统计大小（`DirSize` 模式见 scripts/scan.ps1）
3. **读配置定数据位置**：聊天/文件类数据的位置必写在应用配置里（ini/json/注册表 `HKCU:\Software\<厂商>`），先读配置再决定"清缓存"还是"迁数据"
4. **识别缓存特征**：目录名含 `cache`/`tmp`/`log`/`update`/`upgrade`/`crash`/`telemetry`/哈希命名的文件堆 → 绿区；`session`/`history`/`conversation`/`db` → 黄区需确认
5. **锁定确认**：尝试清不掉的就是被锁的，用进程/服务排查（scripts/find-lockers.ps1）

## 系统级大文件（需管理员/特殊操作）

| 文件/目录 | 大小 | 处理 |
|---|---|---|
| `C:\hiberfil.sys` | ≈内存大小 | `powercfg /h off`（管理员，可逆） |
| `C:\pagefile.sys` | 30-40GB | 不动；缩小的收益小于风险 |
| `C:\Windows\SoftwareDistribution\Download` | 波动 | 磁盘清理工具 |
| WSL 发行版 vhdx | 随使用增长 | `wsl --export/--import` 迁移 |