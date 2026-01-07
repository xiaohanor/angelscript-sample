# 核心设置模块 (Core Settings Module)

## 概览 (Overview)
此目录包含游戏设置系统的业务逻辑。它负责连接抽象的设置值（如 "High Dynamic Range"）与具体的引擎参数（Wwise RTPCs）。

## 关键组件 (Key Components)

### `GameSettingsApplicator.as`
这是核心的单例类 (`UGameSettingsApplicator`)，用于管理游戏设置的状态。

*   **RTPC Definitions:** 定义音频的 Wwise 实时参数控制 (RTPC) ID（例如 `Rtpc_MasterVolume`, `Rtpc_SpeakerSettings_Nightmode`）。
*   **Platform Specifics:** 根据运行平台确定默认设置（例如，在 "Sage" 平台上强制使用 TV 扬声器模式）。
*   **Application Logic:**
    *   `Initialize()`: 设置初始默认值。
    *   `SetObjectsActiveRtpc()`: 直接与 Audio Engine 通信。
    *   `SettingsToDynamicRange`: 将枚举设置映射到具体的音频动态范围值。
*   **Event Broadcasting:** 暴露事件如 `PostSpeakerConfigUpdates`，以便 UI 可以对硬件更改（如声道配置更改）做出反应。

### `DefaultSettingsComponent.as`
*(推测)* 可能处理将默认设置行为附加到特定 Actor 或 Player 上。

## 功能流程 (Functional Flow)
1.  从 `GameSettings` 系统接收设置更改。
2.  解释更改（例如，"Voice Volume" 更改为 5）。
3.  调用引擎级函数（例如 `AudioComponent::SetGlobalRTPC`）以使更改立即生效（可见/可听）。