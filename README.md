# c-disk-cleaner-pro

Windows C 盘 / 数据盘**安全清理与迁移**的 Agent Skill。只读扫描 → 分级报告 → 批量回收站清理 → 锁定排查 → 复核，**绝不硬删除**。

> **出处声明**：本 skill 沿用第三方 skill **kunlun-pc-cleaner**（只读扫描→哈希比对→风险分级→移入废纸篓）的分级处置框架与"绝不硬删除"核心原则，在其基础上融入以下实战增强：
> - Win32 SHFileOperation 批量回收站清理（绕开 VB API 失效问题，快约 100 倍）
> - 回收站配额防护（防止大文件被静默永久删除）
> - 文件锁定源排查与降级隔离策略
> - 缓存迁移到数据盘的标准流程（HuggingFace/pip/npm/uv 等 8 个环境变量）
> - 软件彻底卸载模板（DevEco Studio / Docker Desktop 实战案例）
> - 24 条来自真实清理会话的踩坑记录

## 为什么需要它

随手 rm -rf 或"清理大师"式工具的问题：**误删不可逆**。本 skill 的每一轮清理都遵循：

    只读扫描 → 分级报告 → 用户确认 → 移入回收站（可还原） → 复核 → 用户清空回收站

误删的文件在清空回收站前都能一键还原。

## 安装

把本目录放入 Agent 的 skills 目录（如 ~/.agents/skills/c-disk-cleaner-pro），或按你的 Agent 平台的 skill 安装方式导入。

## 快速上手

对 Agent 说：「C 盘满了，帮我安全清理」
Agent 会：只读扫描 → 出分级报告（绿=可再生/黄=需确认/红=不动）→ 等你勾选 → 批量清理

手动跑脚本（不经过 Agent 也可以）：

    # 1. 只读扫描（不动任何文件）
    powershell -ExecutionPolicy Bypass -File scripts/scan.ps1
    # 2. 查看回收站真实占用
    powershell -ExecutionPolicy Bypass -File scripts/recycle-stats.ps1
    # 3. 编辑 clean.json 勾选要清的目标，然后批量清理（移入回收站）
    powershell -ExecutionPolicy Bypass -File scripts/clean-batch.ps1 -Manifest clean.json
    # 4. 清理后自己清空回收站，空间才真正释放

## 脚本一览

| 脚本 | 用途 |
|---|---|
| scripts/scan.ps1 | 只读审计：磁盘/Top 目录/Temp/大文件>400MB/旧文件>180 天 |
| scripts/clean-batch.ps1 | 批量移入回收站：自动调配额 + 200/批 SHFileOperation + 锁定隔离 |
| scripts/find-lockers.ps1 | 排查"文件被占用"的真凶（进程/服务/残留后台任务） |
| scripts/recycle-stats.ps1 + recycle-bin-api.cs | 回收站真实占用统计（SHQueryRecycleBin） |

## 参考文档（精华）

- references/pitfalls.md — 24 条实战踩坑：回收站 API 失效、配额静默硬删、PowerShell 循环变量残留导致误删注册表键、dism 后不重启导致卸载器挂死……每条 = 症状 → 根因 → 解法
- references/cache-locations.md — 缓存位置知识库：微信 4.x/QQ NT/企微/罗技 G HUB/JetBrains/各 AI Agent Harness 的数据路径、锁定者、迁移变量
- references/uninstall-guide.md — 彻底卸载模板：官方卸载器超时保护、残留核验清单、DevEco/Docker 实战案例

## 安全承诺

- 全程不执行 rm -rf 等不可逆删除（除非用户对"程序残留"明确授权）
- 重复文件以 SHA-256 相同为准，同名不同内容绝不合并
- .git、.ssh、.env、项目源码、音色/素材库永远不碰
- 清理动作先报告后执行，删除决策由用户确认

## 兼容性

Windows 10/11，Windows PowerShell 5.1+（无需管理员，除非涉及系统服务）。适用于任何支持"读取 SKILL.md + 执行 PowerShell"的 Agent 平台。

## License

MIT