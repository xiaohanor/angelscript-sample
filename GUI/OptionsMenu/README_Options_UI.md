# 选项菜单 UI 模块 (Options Menu UI Module)

## 概览 (Overview)
此目录包含选项菜单的用户界面实现。它处理所有游戏设置的显示、导航和用户交互。

## 关键组件 (Key Components)

### 主容器 (Main Container)
*   **`OptionsMenu.as`**: 根 Widget 类 (`UOptionsMenu`)。它管理顶层标签导航、页面容器和全局按钮（Back, Reset, Legal）。

### 页面实现 (Page Implementations)
每个设置类别都有其自己的页面类，继承自 `UOptionsMenuPage`：
*   **`AudioOptionsMenuPage.as`**: 音频设置（音量，扬声器设置）。它包含根据硬件能力显示/隐藏 "3D Audio" 选项的逻辑。
*   **`GameOptionsMenuPage.as`**: 游戏性特定开关。
*   **`GraphicsOptionsMenuPage.as`**: 视觉设置。
*   **`InputOptionsMenuPage.as`**: 控制器/键盘绑定和灵敏度。

### 可重用 Widgets (Reusable Widgets)
系统使用一组自定义 Widgets 来确保一致的样式和行为：
*   **`UOptionWidget`**: 所有选项元素的基础类。处理焦点、悬停和标准事件 (`Apply`, `Reset`)。
*   **`UOptionEnumWidget`**: 用于多选设置（例如，Speaker Type: TV / Headphones / Speakers）。
*   **`UOptionSliderWidget`**: 用于连续值（例如，Volume 0-100）。
*   **`UOptionTextWidget`**: 用于只读状态或简单开关。

## 交互模式 (Interaction Pattern)
1.  **Construction:** 页面使用 `PreConstruct` 和 `Construct` 来初始化 Widgets。
2.  **Binding:** Widgets 绑定到 `GameSettingsApplicator` 以监听外部更新（例如，通过 `SubscribeToGameSettings`）。
3.  **Dependency Logic:** 页面实现基于其他选项启用/禁用选项的逻辑。
    *   *示例:* 在 `AudioOptionsMenuPage.as` 中，`UpdateNightmode()` 检查基于当前 `SpeakerType` 是否应允许点击 "Night Mode"。