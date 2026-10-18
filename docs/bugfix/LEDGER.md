# Bug 修复台账（claude/bugfix-batch1，基于 main @ 3f13e46）

## 待修清单（用户指定 + GitHub issues）
3. **#203 任务栏网速小部件固定宽度** —— 宽度随网速抖动导致左侧图标晃动。最小修：布局宽度钳制/等宽数字。

## 修复记录（每修完一项在此登记）

> ⚠ 循环：第 1 轮未通过编译/测试，改动已回退，本文件里属于该轮的"已改"条目作废。留证 tmp/failed-round-1.diff

### 1. [用户报告] MaterialDesign dock tooltip 显示两次 —— 已修（2026-10-19）
- **根因**：`DockIcon.qml` 的独立 tooltip Loader 用 `!_usesSharedMagnification` 作互斥条件，但 `_usesSharedMagnification` 只在距离放大开启（`AppearanceTokens.dock.magnificationEnabled === tokens.isMacos` 或用户设了 hoverScale）时为真。非 macOS 风格（如 MaterialDesign）放大默认关闭 → Loader 激活；而共享标签路径（`DockContainer.updateNameLabel` → `selectNameTarget`）不依赖放大模式、同样激活 → 同一图标同时出现 DockAppNameTooltip 弹窗 + 共享 DockNameLabel。
- **修复**：`shell/desktop/modules/dock/DockIcon.qml:683-695` —— 新增 `readonly property bool _dockOwnsNameLabel: magnificationRoot !== null && typeof magnificationRoot.updateNameLabel === "function"`（与既有 `updateDockName()` 的判据一致），Loader 的 active 条件由 `!_usesSharedMagnification` 改为 `!_dockOwnsNameLabel`。互斥从"放大模式"改为"标签所有权"，与注释本意一致；无宿主共享标签的孤立宿主仍走懒加载弹窗回退。
- **验证**：`cmake --preset debug` + `cmake --build --preset debug` 通过；场景验证 `tmp/bugfix-shots/dock-tooltip-mutex.qml`（经 `run-tooltip-mutex.py` 在 kwin_wayland --virtual + quickshell software 后端下运行）：Dock 宿主（有 updateNameLabel、无 magnificationFor，模拟非 macOS 风格）hover 时 `loader.active=false`，孤立宿主（无共享标签）hover 时 `loader.active=true`，输出 `TOOLTIP_MUTEX_PASS`；截图 `tmp/bugfix-shots/dock-tooltip-mutex.png`（场景级抓图，图标位图为占位、状态断言以控制台输出为准）。
- **残留风险**：本仓库当前所有 DockIcon 均由 DockContainer 实例化并带共享标签，Loader 实际成为死路径（保留供外部非 Dock 宿主使用）。另：合同测试 `shared/qml/test_visual_contract.mjs` 中 "built-in status tooltips use a black background" 断言为 main 上既有失败（ba5f538 改了 StatusTooltip.qml 配色未同步测试），与本次改动无关。

> ⚠ 循环：第 2 轮未通过编译/测试，改动已回退，本文件里属于该轮的"已改"条目作废。留证 tmp/failed-round-2.diff

### 2. [#224] Control Center 声音面板非 ASCII 设备名显示 (null) —— 已修（2026-10-19）
- **根因**：上游 pactl 缺陷，非本仓库编解码问题。`runAudioOutputs`（platform/src/daemon/PlatformServerAudio.cpp）用 `pactl --format=json list sinks` 取设备列表，而 pactl 17.0 的 JSON 写出器拒绝非 ASCII 字节：实测对含中文 description 的 sink 打印 `Invalid non-ASCII character: 0xffffffe4` 并把该字段输出为字面 `(null)`（glibc printf 对 NULL 的占位），随后原样进入 JSON → QML。文本模式 `pactl list sinks` 在任意 locale（含 LC_ALL=C）下均原样输出 UTF-8，与此无关的 locale 设置（如 QProcess 环境）不是成因。
- **修复**：`platform/src/daemon/PlatformServerAudio.cpp:144-199` —— sink 列表调用由 `--format=json list sinks` 改为 `list sinks`，按行解析顶层字段（`\tName:` / `\tDescription:`，Sink # 头分隔；属性块缩进更深不会误配），`QString::fromUtf8` 解码后构建与原 JSON 路径完全相同的 outputs 数组。首次 `--format=json info`（仅取 ASCII 的 default_sink_name）保持不变。空解析/非零退出沿用原错误回复。
- **验证**：`cmake --preset debug` + `cmake --build --preset debug` 通过（kos-platform 重链接）。逻辑验证 `tmp/bugfix-shots/verify_audio_outputs_utf8.cpp`（解析块逐字复制自修复后代码，对真实 pactl 输出断言）：创建 `device.description=中文测试音箱` 的 module-null-sink，解析结果 `description=[中文测试音箱]`、isDefault 正确，输出 `AUDIO_OUTPUTS_UTF8_PASS`；修前同一场景 JSON 路径返回 `(null)` 已先实测复现。测试 sink 已卸载，系统无残留。合同测试不适用（纯 C++ 后端改动，不涉及 QML 视觉）。
- **残留风险**：daemon 为常驻进程，需重启 kos-platform 后新逻辑才生效（本机旧实例未动）。依赖顶层字段的单 tab 缩进锚点，若未来 pactl 改变文本格式缩进需同步；多行/含 `\r` 的 description 未特殊处理（现有设备均不出现）。

> ⚠ 循环：第 3 轮未通过编译/测试，改动已回退，本文件里属于该轮的"已改"条目作废。留证 tmp/failed-round-3.diff
