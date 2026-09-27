---
name: c-disk-cleaner-pro
description: Windows C 盘/数据盘安全清理与迁移专家流程。只读扫描→分级报告→批量回收站清理→锁定排查→复核，绝不硬删除。当用户提到磁盘清理、C盘满了、C盘飘红、空间不足、缓存清理、临时文件、大文件审查、重复文件、软件卸载残留、缓存迁移到其他盘、回收站、磁盘瘦身，或要求审计 Program Files/AppData/Documents 等目录、把 IM、浏览器、开发工具链、AI 模型缓存等应用数据迁移到其他盘时，都应使用本 skill。基于 kunlun-pc-cleaner（第三方 skill）的分级处置框架，融合大量 Windows SHFileOperation/回收站 API 实战经验。
---

# C-Disk Cleaner Pro — Windows 磁盘安全清理与迁移

> **出处声明**：本 skill 沿用第三方 skill **kunlun-pc-cleaner**（电脑磁盘清理：只读扫描→哈希比对→风险分级→移入废纸篓）的分级处置框架与核心原则，在其基础上融入实战验证的 Windows API 批量清理、锁定排查、缓存迁移经验与踩坑记录。原 skill 的分级方法论是本 skill 的骨架。

## 核心原则（硬规则，不可绕过）

1. **绝不硬删除**。一切清理默认走回收站（SHFileOperation + FOF_ALLOWUNDO）；仅用户明确授权的"确认不要的程序残留"才允许 `Remove-Item -Force`。
2. **只读扫描先行**。先出分级报告（🟢可再生 / 🟡需确认 / 🔴不动），用户勾选范围后才动手。
3. **动手前调大回收站配额**。超配额的大文件会被 Windows **静默永久删除**。
4. **密钥/源码/版本库不碰**：`.ssh`、`.env`、`.git`、项目源码、音色库、素材库永远标红。
5. **系统目录不碰**：`C:\Windows`、`Program Files` 下的软件本体、驱动。
6. **每批 ≤10 个逻辑项**，复核 free 空间后再继续。

## 目录处理目标

| 目标类别 | 典型路径 | 目标 |
|---|---|---|
| 开发缓存 | pip/npm/uv/huggingface/gradle/JetBrains 等 | 清空或迁出系统盘（配合环境变量） |
| AI 模型缓存 | `~/.cache`、`HF_HOME`、`TORCH_HOME`、`MODELSCOPE_CACHE` | 迁移到数据盘并设环境变量 |
| 应用更新残留 | 各应用的 update/upgrade/updater 缓存目录（IM、外设厂商套件、桌面客户端） | 直接清（会再生成） |
| 浏览器/运行时缓存 | Edge/Chrome 的 Cache/Code Cache、应用内嵌浏览器（CEF）缓存 | 清（应用重开自动重建） |
| 大文件审查 | >500MB 单文件（安装包/iso/虚拟磁盘） | 逐个确认后删 |
| 旧文件归档 | Downloads/Pictures/Screenshots mtime>180 天 | 用户确认后移回收站 |
| 软件卸载残留 | 官方卸载器跑完后的目录/注册表/服务 | 全量核验清单式清除 |
| 重复文件 | SHA-256 相同才算重复（同名不同内容不算） | 保留一份 |

## 操作流程（SOP，7 步）

### Step 1 — 只读扫描
运行 `scripts/scan.ps1`：磁盘现状 → 用户目录/AppData Top15 → Temp → 大文件 >400MB → 旧文件 >180 天。**此阶段不动任何文件。**
同时运行 `scripts/recycle-stats.ps1` 摸清回收站现状。

### Step 2 — 分级报告
按文末模板输出报告交用户确认。重复文件判定必须 SHA-256 相同（`Get-FileHash`），同名不同内容绝不合并。

### Step 3 — 回收站配额与占用核查

```powershell
# 调大配额，防止大文件被静默硬删
Get-ChildItem 'HKCU:\Software\Microsoft\Windows\CurrentVersion\Explorer\BitBucket\Volume' | ForEach-Object {
  Set-ItemProperty $_.PSPath -Name MaxCapacity -Value 102400 -Type DWord
  Set-ItemProperty $_.PSPath -Name NukeOnDelete -Value 0 -Type DWord
}
```

统计回收站用 `scripts/recycle-stats.ps1`（SHQueryRecycleBin API）。**不要枚举 `C:\$Recycle.Bin`**——SID 子目录权限会中断枚举，显示 0 不可信。

### Step 4 — 锁定预检
运行 `scripts/find-lockers.ps1`，确认目标缓存没有被运行中的应用/服务/后台清理任务锁定。常见锁定源见 `references/cache-locations.md`。

### Step 5 — 批量清理（主力）
把目标路径清单写入 JSON，运行 `scripts/clean-batch.ps1 -Manifest clean.json`：
- SHFileOperation（P/Invoke，FOF_ALLOWUNDO）**批量**移入回收站（每批 200 个 null 分隔路径，比逐文件快约 100 倍）
- 整批失败时自动降级逐个重试，隔离出被锁定的文件
- 输出 moved/locked 清单与释放量

### Step 6 — 处理锁定项
提示用户关闭对应应用，或提权停对应后台服务（典型如厂商更新服务，服务名可用 `Get-Service` 按厂商关键词定位）→ 清理 → 重启服务。

### Step 7 — 复核与提醒
复核磁盘 free；**提醒用户手动清空回收站**——移入回收站不释放空间（同盘），这一步只能用户做。

## 缓存迁移到其他盘（进阶能力）

对可再生缓存，删除不如迁移。标准动作：
1. 在数据盘建目标目录（如 `D:\DevCache`、`D:\AI_Cache`，按类别分目录更清晰）
2. `robocopy <src> <dst> /E /MOVE`
3. 设置环境变量并广播 WM_SETTINGCHANGE（Machine 级需提权，User 级不需要）：`HF_HOME`、`HF_HUB_CACHE`、`TORCH_HOME`、`MODELSCOPE_CACHE`、`UV_CACHE_DIR`、`PIP_CACHE_DIR`、`NPM_CONFIG_CACHE`
4. **实测验证**（不是只看变量）：真实落盘测试（如 `pip download six` 后检查新目录增长）
5. 提醒用户重启已开的应用

## 软件彻底卸载模板

顺序（勿颠倒）：退程序 → 确认无"功能启用后未重启"的 pending → 官方卸载器（带超时保护；静默秒退≠删干净）→ 核验目录/服务/注册表 Uninstall 条目/PATH → 删数据残留。详见 `references/uninstall-guide.md`。

## 经验总结（精华 12 条，完整版见 references/pitfalls.md）

| # | 坑 | 解法 |
|---|---|---|
| 1 | VB `FileSystem.DeleteDirectory(回收站模式)` 报 "system call level is not correct" | 弃用，改 SHFileOperation P/Invoke |
| 2 | 回收站超配额**静默硬删** | 动手前调 MaxCapacity / NukeOnDelete=0 |
| 3 | 枚举 `$Recycle.Bin` 统计显示 0（SID 权限中断） | 用 SHQueryRecycleBin API |
| 4 | 移入回收站后 free 不变 | 正常（同盘占用），清空回收站才释放 |
| 5 | SHFileOperation rc=124/120/32 | 长路径/权限/占用 → 批量失败降级逐个隔离 |
| 6 | 逐文件删除仅 6-25 文件/秒 | 批量 null 分隔路径（200/批）快约 100 倍 |
| 7 | PowerShell 循环内 API 失败时变量残留上轮值 → 误删注册表键 | 循环体先 `$var = $null` |
| 8 | 内联 `-Command` 的 `$` 被外层吞 | 一律写 .ps1 文件用 `-File` 执行 |
| 9 | 提权子进程输出不回传 | 子脚本写日志文件，父进程读 |
| 10 | 后台清理任务自己持句柄 → "文件被占用"假象 | 先确认旧任务退出再重试 |
| 11 | dism 启用 Windows 功能后不重启 → 卸载器无限挂死 | 启用功能后先重启再装/卸 |
| 12 | SYSTEM 服务进程杀不掉（典型：厂商后台更新服务） | 正路 Stop-Service + 提权，清完把服务拉起来 |

## 参考文件（按需读取）

| 文件 | 何时读 |
|---|---|
| `references/pitfalls.md` | 任何删除/迁移操作动手前，必读 |
| `references/cache-locations.md` | 定位某应用的缓存/数据/锁定源时 |
| `references/uninstall-guide.md` | 需要彻底卸载软件（含 JetBrains 系 IDE/Docker 实战案例）时 |
| `scripts/*.ps1` | 对应 SOP 步骤直接运行 |

## 脚本清单

| 脚本 | 用途 | 用法 |
|---|---|---|
| `scripts/scan.ps1` | 全盘只读扫描 | `powershell -File scan.ps1` |
| `scripts/recycle-stats.ps1` | 回收站真实占用（SHQueryRecycleBin） | `powershell -File recycle-stats.ps1` |
| `scripts/find-lockers.ps1` | 锁定进程排查 | 编辑 $targets 后运行 |
| `scripts/clean-batch.ps1` | 批量回收站清理（配额检查+降级隔离） | `powershell -File clean-batch.ps1 -Manifest clean.json` |

clean.json 格式：

```json
{ "targets": [ { "path": "C:\\Users\\me\\AppData\\Local\\npm-cache", "name": "npm cache", "level": "green" } ] }
```

## 报告输出模板

```markdown
## 磁盘清理报告（日期）
### 空间现状
C: 总 XXX GB，free XX GB（已用 XX%）
### 可释放清单
| 路径 | 大小 | 分级 | 说明 |
### 执行结果
| 项目 | moved | locked | 释放 |
### 待用户操作
- [ ] 清空回收站（本批移动的文件全部可还原）
```

## 致谢

- **kunlun-pc-cleaner**（第三方 skill）— 本 skill 的分级处置框架（只读扫描→哈希比对→风险分级→移入废纸篓）与"绝不硬删除"原则源自该 skill，在此致谢并注明沿用关系。
