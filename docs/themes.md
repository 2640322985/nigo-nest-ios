# 主题外观

入口：「我的」顶部画板按钮或「我的 → 主题外观」。

- 黑白校园：默认主题，保留原有黑白层次、手写标题和学生人物。
- 课间手账：参考用户指定效果图，采用奶油纸张、细纸纹、红蓝笔色、横线便签、胶带点缀、原创红围巾猫咪和校园线稿。正文保持系统字体，系统导航与玻璃底栏继续使用原生控件。

主题跟随系统深浅色。通过独立的本地外观偏好保存选择，不绑定账号、不改登录会话。SwiftUI 环境传递样式，不通过重建根视图切换，保留导航、表单及页面状态。无效或缺失的偏好回退黑白校园。

偏好测试在三个独立进程中验证默认值、保存、重新读取、切回黑白、无效值恢复及清除。截图从首次保存手账主题开始，后续页面重启不再传入主题覆盖参数，复核偏好持久化；同时导出主题设置页及黑白回归画面。Release 不包含截图覆盖或偏好测试入口。

验证源码：`f9f60c8`。[GitHub Actions 成功记录](https://github.com/ithtelab/nigo-nest-ios/actions/runs/41601782830)。三个偏好测试阶段、主应用与小组件 Debug/Release 编译通过，九张原生截图通过空白检测并已人工检查，见[截图集](screenshots/themes/README.md)。截图使用 iPhone 17 / iOS 27.0 模拟器与演示数据；不代表实体手机或完整交互自动化验收。

## 原创资源

内置 image_gen 生成透明位图，参考图片只作风格参考，不将效果图切片当界面使用。

- `NigoNest/Assets.xcassets/JournalCat.imageset/artwork.png`
- `NigoNest/Assets.xcassets/JournalCampus.imageset/artwork.png`

完整提示词见 [theme-art-prompts.md](theme-art-prompts.md)。纸纹、横线与胶带采用原生绘制，降低视觉噪声并适配深浅色。
