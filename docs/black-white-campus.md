# 黑白校园界面改造

选型：黑白灰、少量手写标题、原创学生插画，系统导航与操作使用原生材质。

## 页面和功能

- 今日：当天课程、课表、空教室、场馆与好友入口。课程来自按账号保存的导入课表，未导入显示空状态。由于接口未提供已核实的节次时间映射，只显示真实节次，不编造开课时间或倒计时；主卡明确标注「今日首课」。
- 广场：保留真实分页、点赞、评论、回复、发帖与同学资料，改为平面信息流，增加刷新与空状态。
- 消息：集中好友聊天、好友申请、通知和互动，读取实际未读数。
- 我的：资料、积分签到、排行榜、动态、好友、预约和同伴管理；学业工具按原有功能开关与年级限制展开。
- 各标签有独立原生导航栈；保留 iOS 18 回退和深浅色系统语义颜色。

## 云端验证

`Build iOS` 使用 GitHub Actions Xcode 27 环境，编译主应用与小组件，运行 iPhone 17 **模拟器**并导出深浅色、登录、课表、大字体截图。随后执行导航 UI 测试，并单独编译 Release。

截图由实际 SwiftUI 页面产生。Debug 专用 `-preview` 入口通过本地数据传输显示演示内容，不读取用户学校账号、不连接生产服务器、不替代生产界面。Release 不编译预览入口与本地响应。截图标注演示数据，不代表线上数据或实体手机测试。

## 资源

标题使用 Google Fonts 的 Ma Shan Zheng，SIL OFL 许可证附于 `NigoNest/Resources/Fonts/OFL.txt`。字体来源：https://github.com/google/fonts/tree/main/ofl/mashanzheng 。

`CampusWalking`、`CampusReading` 是本次内置 image_gen 生成的原创透明位图，并非另一课表项目素材。正文、课程和用户数据使用系统字体。

生成共同提示词：Generate an original black-and-white hand drawn editorial illustration for a clean campus iOS app. Transparent background, single isolated full-body young adult student, generous transparent margins. Fine confident black ink contours, flat solid black hair/clothing patches, white clothing areas opaque white, no gray shading, no scene, no typography, no ground line, no shadows, no adjacent figures, no decorative objects floating. Natural stylized adult proportions, small face, tiny dot eyes, warm quiet personality, not chibi. Whole body and all items visible, suitable for 100pt UI illustration. Completely original design.

走路人物补充：Student with short curly hair, round glasses, loose white overshirt and black wide-leg trousers, canvas tote on shoulder, walking gently carrying a rolled sketchbook, facing left. Single figure.

读书人物补充：Student with short bob hair, black sleeveless sweater over white blouse, light trousers, sitting cross-legged atop one thick book while reading a small notebook. Facing slightly right. Single figure.
