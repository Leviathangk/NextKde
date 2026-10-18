# Bug 修复台账（claude/bugfix-batch1，基于 main @ 3f13e46）

## 待修清单（用户指定 + GitHub issues）
2. **#224 fix(control-center): keep UTF-8 audio output names** —— 非 ASCII 设备名在 Control Center 声音面板显示 (null)。
   按模板写最小修复（不得引入 Qt 以外依赖），注意 locale 编解码路径。
3. **#203 任务栏网速小部件固定宽度** —— 宽度随网速抖动导致左侧图标晃动。最小修：布局宽度钳制/等宽数字。

## 修复记录（每修完一项在此登记）

> ⚠ 循环：第 1 轮未通过编译/测试，改动已回退，本文件里属于该轮的"已改"条目作废。留证 tmp/failed-round-1.diff

### 1. [用户报告] MaterialDesign dock tooltip 显示两次 —— 已修（2026-10-19）
- **根因**：`DockIcon.qml` 的独立 tooltip Loader 用 `!_usesSharedMagnification` 作互斥条件，但 `_usesSharedMagnification` 只在距离放大开启（`AppearanceTokens.dock.magnificationEnabled === tokens.isMacos` 或用户设了 hoverScale）时为真。非 macOS 风格（如 MaterialDesign）放大默认关闭 → Loader 激活；而共享标签路径（`DockContainer.updateNameLabel` → `selectNameTarget`）不依赖放大模式、同样激活 → 同一图标同时出现 DockAppNameTooltip 弹窗 + 共享 DockNameLabel。
- **修复**：`shell/desktop/modules/dock/DockIcon.qml:683-695` —— 新增 `readonly property bool _dockOwnsNameLabel: magnificationRoot !== null && typeof magnificationRoot.updateNameLabel === "function"`（与既有 `updateDockName()` 的判据一致），Loader 的 active 条件由 `!_usesSharedMagnification` 改为 `!_dockOwnsNameLabel`。互斥从"放大模式"改为"标签所有权"，与注释本意一致；无宿主共享标签的孤立宿主仍走懒加载弹窗回退。
- **验证**：`cmake --preset debug` + `cmake --build --preset debug` 通过；场景验证 `tmp/bugfix-shots/dock-tooltip-mutex.qml`（经 `run-tooltip-mutex.py` 在 kwin_wayland --virtual + quickshell software 后端下运行）：Dock 宿主（有 updateNameLabel、无 magnificationFor，模拟非 macOS 风格）hover 时 `loader.active=false`，孤立宿主（无共享标签）hover 时 `loader.active=true`，输出 `TOOLTIP_MUTEX_PASS`；截图 `tmp/bugfix-shots/dock-tooltip-mutex.png`（场景级抓图，图标位图为占位、状态断言以控制台输出为准）。
- **残留风险**：本仓库当前所有 DockIcon 均由 DockContainer 实例化并带共享标签，Loader 实际成为死路径（保留供外部非 Dock 宿主使用）。另：合同测试 `shared/qml/test_visual_contract.mjs` 中 "built-in status tooltips use a black background" 断言为 main 上既有失败（ba5f538 改了 StatusTooltip.qml 配色未同步测试），与本次改动无关。

> ⚠ 循环：第 2 轮未通过编译/测试，改动已回退，本文件里属于该轮的"已改"条目作废。留证 tmp/failed-round-2.diff
