# RightStatusShot（独立实验版）

状态栏右侧三分之一区域内，单指从左向右滑动，调用系统截图。
手指必须从右侧区域内起滑，不是从整个屏幕的最左边滑到最右边。

目标设备：iPhone 13 Pro Max / iOS 15.6 / RootHide / arm64e。
只注入 SpringBoard；不隐藏状态栏、不创建覆盖窗口、不修改辅助功能快捷键。
状态栏不可见时没有触发区域。第三方 App 和横屏下的表现需真机验证。

独立包名、独立动态库，只 hook `_UIStatusBar -didMoveToWindow`。
与 TapFlash 4.1.2 的 AVFlashlight/init、SBLockHardwareButton/doublePress/triplePress 不重合。
不要求安装 TapFlash，也不替换它。不要同时启用其他插件在相同区域的右滑动作。

## 实现与限制

参考 SquidGesture 免费版的系统右滑识别器和 SpringBoard `takeScreenshot` 路径；
不是复制整个原插件或还原 Pro 源码。原版的 initWithStyle hook 改为视图加入窗口后挂载，
使用独立 NSObject 作为代理和动作接收者；同一个视图只挂载一次。
截图只在成功识别手势后执行，不在构造函数或视图挂载时执行。
捕获 Objective-C 异常后本次 SpringBoard 会话停用本插件；这不能防住原生崩溃、死锁或系统 watchdog。

编译和边界测试通过不代表真机稳定。此前发生过白苹果且没有日志，原因仍未证实。
安装前需具备你当前越狱环境可用的禁用插件/恢复入口；没有恢复手段时不要安装实验包。
卸载 RightStatusShot 可移除本插件，不需要卸载 TapFlash。

## 构建

使用 RootHide Theos：`make clean package FINALPACKAGE=1`。
边界检查：`cc -std=c11 -Wall -Wextra -Werror test_region.c -o /tmp/rightstatusshot-check && /tmp/rightstatusshot-check`。
