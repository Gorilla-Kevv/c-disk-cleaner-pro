# Uninstall Guide — 软件彻底卸载模板与实战案例

## 通用流程（勿颠倒顺序）

1. **退出程序**：托盘退出 + 任务管理器确认无主进程/子进程
2. **检查 pending 重启**：`HKLM:\...\Component Based Servicing\RebootPending` 存在则先重启（坑 C1，见 pitfalls.md）
3. **官方卸载器**：静默模式带超时保护（后台运行 + 轮询退出码，900s 超时强杀）；**秒退 ≠ 删干净**，事后核验
4. **残留核验清单**：安装目录、`%APPDATA%`/`%LOCALAPPDATA%`/`%PROGRAMDATA%` 数据目录、开始菜单/桌面快捷方式、注册表 Uninstall 条目 + 厂商 hive、PATH 条目、最近文档
5. **数据残留**：最后删除（可能含用户数据，先列表确认）
6. **验证**：全盘扫描厂商关键词 = 0 命中

## 案例 1：DevEco Studio（JetBrains 系）

- 官方卸载器：`<install>\bin\Uninstall.exe /S`，本次 10 秒退出 code=0 但目录仍在 → 补刀 `Remove-Item`
- C 盘数据：`%APPDATA%\Huawei\<产品名>`（含插件 0.5GB）、`%LOCALAPPDATA%\Huawei`、`~\.hvigor`、`~\.ohpm`
- 注册表：`HKLM:\SOFTWARE\WOW6432Node\Microsoft\Windows\CurrentVersion\Uninstall\<产品>` + `HKLM:\SOFTWARE\WOW6432Node\Huawei`
- 教训：**遍历注册表判断归属时循环变量必须先置 null**，否则会误删相邻键（本次误删 Windows 占位键 DirectDrawEx/DXM_Runtime 后已重建）
- JetBrains 系通用残留位置：`%APPDATA%\<Vendor>\<产品><版本>`、`%LOCALAPPDATA%\<Vendor>\<产品><版本>`

## 案例 2：Docker Desktop（WSL2 后端）

- 前置判断"是否有数据"四条件：无 WSL 发行版 + 无 ext4.vhdx + 无 com.docker.service + 无 Uninstall 条目 → 全满足才可放心硬清
- 官方卸载器：`"Docker Desktop Installer.exe" uninstall`
- WSL 发行版清理：`wsl --shutdown` → `wsl --unregister docker-desktop[-data]`
- **大坑**：dism 启用 WSL 后未重启时，卸载器钩子调用 WSL 组件会无限挂起（窗口空白）→ 先强杀卸载进程，重启电脑后再卸载
- 安装参数化（可装到任意盘）：
  `install --accept-license --backend=wsl-2 --installation-dir=D:\Docker --wsl-default-data-root=D:\Docker\wsl --hyper-v-default-data-root=D:\Docker\hyperv --windows-containers-default-data-root=D:\Docker --no-windows-containers --quiet`
- 数据迁移（已装好）：Settings → Resources → Advanced → Disk image location；或 `wsl --export/--unregister/--import docker-desktop-data`

## 案例 3：零初始化软件的"假占用"

某软件从未运行过，但清理其目录报"文件被占用"。根因：**之前转入后台的清理脚本自己持有句柄**。
处理：枚举所有 powershell/pwsh 进程 CommandLine，确认无残留任务后重试，即可成功。

## 硬清授权判据（四条全满足才硬删）

1. 无运行中进程/服务持有该目录
2. 无用户个人数据（会话/聊天/凭证/自建配置）
3. 注册表无 Uninstall 条目（或已确认卸载完成）
4. 用户明确确认
否则：回收站兜底或迁移隔离。