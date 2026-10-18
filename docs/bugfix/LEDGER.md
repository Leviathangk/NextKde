# Bug 修复台账（claude/bugfix-batch1，基于 main @ 3f13e46）

## 待修清单（用户指定 + GitHub issues）
1. **[用户报告] MaterialDesign dock tooltip 显示两次**（两个部分重叠的 tooltip 同时出现）
   线索（侦察已定位）：`shell/desktop/modules/dock/DockIcon.qml:686` 的 Loader（独立 DockAppNameTooltip 弹窗路径）
   与 Dock 共享的 `DockNameLabel`（magnificationRoot.nameLabel 路径）条件存在交集 → 同一图标同时走两条路径。
   注释原文："The Dock owns one label in its existing surface... Non-Dock hosts retain the existing lazy popup fallback."
   → 修法：互斥条件补齐（共享标签路径激活时禁用 Loader，或反之），修完构造两种 host 状态各验一次。
2. **#224 fix(control-center): keep UTF-8 audio output names** —— 非 ASCII 设备名在 Control Center 声音面板显示 (null)。
   按模板写最小修复（不得引入 Qt 以外依赖），注意 locale 编解码路径。
3. **#203 任务栏网速小部件固定宽度** —— 宽度随网速抖动导致左侧图标晃动。最小修：布局宽度钳制/等宽数字。

## 修复记录（每修完一项在此登记）

> ⚠ 循环：第 1 轮未通过编译/测试，改动已回退，本文件里属于该轮的"已改"条目作废。留证 tmp/failed-round-1.diff
