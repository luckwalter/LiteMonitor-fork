# LiteMonitor-fork 分支说明（custom 分支专用）

> 本文件是本分支（custom）的专用说明文档，刻意独立于上游 `README.md`，
> 以减少将来借鉴上游代码时的合并冲突面。如与上游 `README.md` 冲突，以本文件为准。

## 一、本分支的定位与立场

本仓库是 **Diorser/LiteMonitor**（源项目，轻量级 Windows 任务栏硬件监控）的本地化定制分支。

**自 2026-10-14 起，本分支（custom）正式与源项目分道扬镳、独立发展。**

核心立场：

- **借鉴但不回传**：后续仍可 `git fetch upstream` 查看源的修正，并按需借鉴（cherry-pick 单个提交，或对上游 PR 手工合并），但**绝不将本分支的改动回传上游**——不向 `upstream` 提 Pull Request，也不 `push` 到源仓库。
- `upstream` 远端仅作为"借鉴源"保留；`master` 本地分支仅作为上游基线镜像参考，不推送远程。
- 同步策略：定期 `fetch upstream` 浏览新修正，只挑需要的部分借鉴，**不盲目整分支合并**，以避免引入与本地定制冲突的上游改动。

## 二、上游基线（来自源的 pull 内容）

本分支的起点是上游到 **v1.3.6** 的完整代码，对应提交 `169e90a`（Diorser 于 2026-05-16 提交 "build: bump version to 1.3.6"）。

- 本地 `master` 分支与 `upstream/master` **完全对齐**（2026-10-14 实测 `fetch` 后 0 个落后提交），即本分支基线即为最新的上游代码。
- 上游 v1.3.6 内含的关键能力（来自源，本分支未改其逻辑）：

  | 上游提交 | 内容 |
  |---|---|
  | 6a15234 | 新增监控历史功能，优化多项细节 |
  | de159f7 | 重构 PawnIO 驱动安装逻辑，新增版本校验 |
  | 4554e70 | 实现启动前驱动预检查与安装流程 |
  | 90d20e8 | 修复主板温度误报、窗口居中，完善电池传感器预热 |
  | d173294 | 新增插件最小刷新间隔支持 |
  | aec8e56 | 将 LibreHardwareMonitorLib 依赖更新至稳定版 0.9.6 |

> 这部分代码**完全来自源项目**，本分支未做逻辑改动，属于"来自源的 pull 内容"，也是本分支一切本地定制的地基。

## 三、本地主动变更

### 3.1 .NET 升级（net8 → net10）

- 相关提交：`095650c`（feat：目标框架升级 + 部署脚本）、`360fe63`（fix：修复缺失资源导致的构建中断）、`2bf45a2`（merge）。
- **升级原因**：
  - .NET 8 将于 **2026-11-10 停止维护（EOL，End Of Life）**；.NET 10 是**长期支持版（LTS，Long Term Support）**，支持至 **2028-11-14**。
  - 实测自包含发布反而更大（net8 自包含 159 MB，net10 依赖式单文件仅约 6 MB）；且自包含把运行时锁死在包内、不会自动打补丁，安全更新需重新打包。
- **具体改动**：
  - `LiteMonitor.csproj`：`TargetFramework` 由 `net8.0-windows` 改为 `net10.0-windows`；新增 `<NoWarn>$(NoWarn);WFO1000</NoWarn>`（绕过 .NET 9 起 WinForms 设计器序列化检查 WFO1000 的误报，该误报出现在 LiteUI / LiteTreeView / TrendChartControl 自绘控件属性上，**不影响运行时**）。
  - **源码零改动**——仅改 csproj 两行，后续同步上游几乎不会冲突。
  - 新增 `deploy-to-LiteMonitor.bat`：一键发布脚本（见 3.3）。
- **升级成本**：极低。

### 3.2 工程配置与缺失文件补回

- `.gitignore`（新增 33 行）：排除构建产物、本地配置、历史数据等，避免误入版本库。
- `使用说明(必读).txt`（新增 126 行）：上游从未将该文件提交进 git，却一直被 csproj 引用，导致任何人 clone 后构建直接失败（MSB3030）。本分支将其正式入库，并随版本维护本地定制说明（文件末尾 `[5] 本地定制版说明` 章节，与上游 `[1]` 节冲突时以本分支为准）。

### 3.3 本地一键部署脚本

- `deploy-to-LiteMonitor.bat`（69 行）：先 `publish` 到 `publish/_staging` 暂存目录，再**挑选性复制**至 `C:\LiteMonitor`，其中 `settings.json`、`HardwareHistory.json`、`TrafficHistory.json`、`使用说明(必读).txt` **永不被覆盖**（保留用户配置与历史数据）。
- 同时补齐单文件发布模式下不会落盘的两个附属 exe：`resources\LiteMonitor.Updater.exe`、`resources\LiteMonitorFPS.exe`（否则 FPS 计数与检查更新失效）。

## 四、后续借鉴上游修正的约定

- **渠道**：`git fetch upstream` 后查看 `upstream/master` 的新提交。
- **借鉴方式**：优先 `cherry-pick`（摘取）单个提交，或对上游 PR 按 `files` API 的 `patch` 字段手工合并；**不整分支 merge**。
- **已合入本分支的上游 PR**：实验分支 `exp/pr-survey` 已编译与启动验证 **10 个上游社区 PR**，于 2026-10-14 经合并提交 `4e16e7d` 合入 `custom` 主线（实验分支已删远程、仅本地保留备查）：

  | 分类 | PR | 内容 |
  |---|---|---|
  | 硬件 | #586 | 修复 Intel 核显 / AMD APU 占用率不显示（传感器懒激活，根因分析最专业） |
  | 硬件 | #602 | 新增虚拟内存（Commit + Available）显示选项 |
  | 硬件 | #465 | CPU 温度来源可配置（Tctl / Tdie / CCD） |
  | 硬件 | #471 | 机械革命翼龙15 EC 风扇直读 |
  | 任务栏 | #563 | 多屏交界自动隐藏、设置保存回退、低缩放文字挤压三修 |
  | 任务栏 | #600 | 显卡驱动重置后把监控条抬回 Win11 合成层 |
  | 任务栏 | #300 | Win11 任务栏高度自定义 |
  | 插件 | #340 / #503 / #593 | 伦敦现货黄金价格 / 蛟龙16Pro 风扇转速 / 蓝牙设备电量（纯新增，零风险） |

  详细调研见 `.workbuddy/memory/2026-10-14-PR调研.md`。
- **红线**：永不向 `upstream` 提 PR 或 push，本分支独立演进。

## 五、本地部署与运行

- 日常发布：双击仓库根 `deploy-to-LiteMonitor.bat`。
- 运行目录：`C:\LiteMonitor`（维护者的固定运行目录）。
- 发布形态：net10 依赖式单文件（约 6 MB），需本机已安装 .NET 10 运行时（WindowsDesktop.App 10.0.12），双击即用。

## 六、注意事项（运维红线）

1. **⚠️ 自动更新覆盖风险**：`settings.json` 中 `AutoCheckUpdate` 默认 `true`，更新源写死官方（litemonitor.cn / gitee:Diorser / github:Diorser），下载官方 release ZIP 后直接覆盖 `LiteMonitor.exe`。一旦自动更新，net10 定制版会被官方 net8 版替换，连 `使用说明(必读).txt` 也会被旧版覆盖。**处理办法**：把 `AutoCheckUpdate` 改为 `false`，或改掉那三个 URL。
2. **单文件发布的附属 exe**：见 3.3，部署脚本已处理，勿手删。
3. **硬件历史保留期**：`src/Core/HardwareHistoryLogger.cs` 写死 `_retention = 7 天`，过期数据在 `.bak` 中可找回，这是设计如此，延长需改代码。
4. **许可证**：源项目无开源许可证（license 为 null）。本地自用修改无碍；若要公开分发二进制或二次开源，需先取得作者授权。

## 七、分支图谱

```
upstream/master   (Diorser 官方, v1.3.6)
      │   仅 fetch 借鉴，绝不 merge / push 回传
      ▼
master   (本地镜像, 169e90a)   ←── 上游基线，即"来自源的 pull 内容"
      │
      ▼
custom   (维护主线)   ←── 本分支（独立演进）
      ├─ .NET 升级 net8→net10 + 部署脚本        [本地主动变更]
      ├─ 使用说明补回 + .gitignore               [本地主动变更]
      └─ 10 个上游 PR 集成（合并提交 4e16e7d）   [已合入, 实验分支 exp/pr-survey 已删远程仅本地保留]
```

---
*本文件最后更新：2026-10-14*
