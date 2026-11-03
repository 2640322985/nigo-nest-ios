# 双主题实际运行截图

设备：GitHub Actions iPhone 17 / iOS 27.0 模拟器。工具链：Xcode 27.1。页面为实际编译运行的 SwiftUI 界面，使用本地演示数据。

| 页面 | 浅色 | 深色 |
| --- | --- | --- |
| 今日 | ![今日](journal-today-light.png) | ![今日深色](journal-today-dark.png) |
| 广场 | ![广场](journal-plaza-light.png) | ![广场深色](journal-plaza-dark.png) |
| 我的 | ![我的](journal-profile-light.png) | ![我的深色](journal-profile-dark.png) |

| 主题选择 | 黑白主题回归 | 保留主题后的正常登录 |
| --- | --- | --- |
| ![主题外观](journal-theme-picker.png) | ![黑白校园](monochrome-today-light.png) | ![登录页](production-login.png) |

仅首次启动写入手账偏好，之后六次页面启动及正常登录不再覆盖偏好。黑白回归图使用 Debug 临时外观覆盖，不改已保存的手账选择。实际偏好读写、跨进程恢复、切回黑白、无效值回退由独立 Foundation 测试覆盖。

[验证运行](https://github.com/ithtelab/nigo-nest-ios/actions/runs/41601782830) · [功能与资源说明](../../themes.md)
