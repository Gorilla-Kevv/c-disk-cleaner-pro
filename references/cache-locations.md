# Cache Locations — Windows 常见缓存/数据/锁定源知识库

> 实测于 Windows 11 + 微信4.x/QQNT/企微/钉钉类国产应用 + 开发工具全家桶。按"锁定者"和"建议动作"标注。

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
| 鸿蒙 hvigor | `~\.hvigor\project_caches` | 清（构建缓存，43万文件大户） | — |
| JetBrains | `%LOCALAPPDATA%\JetBrains\<IDE>\{index,log,caches,jcef_cache}` | 清（索引重建） | — |
| VS Code | `%APPDATA%\Code\{CachedExtensionVSIXs,CachedData,Cache,logs}` | 清 | — |
| C++ 扩展 | `%LOCALAPPDATA%\Microsoft\vscode-cpptools` | 清 | — |
| NVIDIA DXCache | `%LOCALAPPDATA%\NVIDIA\DXCache` | 清（shader 缓存自动重建） | — |
| Chromium 快照 | `~\.chromium-browser-snapshots` | 清 | — |
| codex 运行时 | `~\.cache\codex-runtimes` | 清 | — |

## 国产应用（数据位置需读配置确认）

| 应用 | 程序数据 | 聊天/文件数据 | 锁定者 | 备注 |
|---|---|---|---|---|
| 微信 4.x | `%APPDATA%\Tencent\xwechat`（update/log/radium/XPlugin） | config `*.ini` 里一行路径 | Weixin.exe + ~90 个 WeChatAppEx | update 会反复累积；radium/XPlugin 删后重下 |
| QQ NT | `%APPDATA%\Tencent\QQNT` | 默认 `%USERPROFILE%\Documents\Tencent Files`，可自定义为任意盘 | QQ.exe | 聊天文件大头通常在自定义盘 |
| 企业微信 | `%APPDATA%\Tencent\WXWork`（cef/wmpf 小程序） | `%USERPROFILE%\Documents\WXWork`（qtCef 是 CEF 缓存可清） | WXWork.exe | 文件位置应用内可改 |
| 腾讯会议 | `%APPDATA%\Tencent\WeMeet\Global` | — | wemeetapp.exe | — |
| 百度网盘 | `%APPDATA%\baidu\BaiduNetdisk` | — | BaiduNetdisk.exe | — |

## 硬件/系统应用

| 应用 | 缓存 | 锁定者 | 处理 |
|---|---|---|---|
| 罗技 G HUB | `C:\ProgramData\LGHUB\cache`（更新下载缓存，可达数 GB） | lghub_agent + **LGHUBUpdaterService（服务）** | 提权停服务→清→启服务→重启 lghub.exe |
| 罗技 depots | `C:\ProgramData\LGHUB\depots` | 同上 | 删后自动重下 |
| Edge/Chrome | `...\User Data\Default\{Cache,Code Cache,GPUCache}` | 多进程 | 逐文件清可清大部分 |
| 缩略图 | `%LOCALAPPDATA%\Microsoft\Windows\Explorer\thumbcache_*.db` | explorer.exe | 停 explorer 再删（可选） |
| 系统临时 | `%LOCALAPPDATA%\Temp` | 各种运行中程序 | 能清多少清多少，重启后再清一次 |
| Windows 更新 | `C:\Windows\SoftwareDistribution\Download` | wuauserv | 磁盘清理工具处理 |

## AI Agent Harness（新型大户）

| Harness | 主目录 | 可清部分 | 说明 |
|---|---|---|---|
| WorkBuddy | `~\.workbuddy`（1.6GB+） | logs/cache/shell-snapshots/pending-telemetry/binaries(重下) | logs 被后台组件锁定；有 skill-cloud-sync |
| Trae CN | `~\.trae-cn` | hub_event_cache；extensions(1.1GB) 重下 | builtin_skills 在 IDE 内部 |
| CodeBuddy | `~\.codebuddy` | logs/diagnostics/skills-marketplace.staging-*（更新失败残留） | 检查 staging-* 孤儿目录 |
| Codex | `~\.codex` | .tmp/tmp/plugins\cache/browser\sessions | — |
| OpenCode | `~\.config\opencode` | node_modules/skills（若是共享库副本） | 配置在 opencode.jsonc |
| CherryStudio | `~\.cherrystudio\install\cache` | npm 缓存 | install 下其余是运行时勿删 |
| 共享技能库 | `~\.agents\skills` | 🔴 永远不清理 | 各 harness 可用 junction 指向它（注意 harness 的云同步可能重建目录） |

## 系统级大文件（需管理员/特殊操作）

| 文件/目录 | 大小 | 处理 |
|---|---|---|
| `C:\hiberfil.sys` | ≈内存大小 | `powercfg /h off`（管理员，可逆） |
| `C:\pagefile.sys` | 30-40GB | 不动；缩小的收益小于风险 |
| `C:\Windows\SoftwareDistribution\Download` | 波动 | 磁盘清理工具 |
| WSL 发行版 vhdx | 随使用增长 | `wsl --export/--import` 迁移 |