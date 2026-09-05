# 核实记录：状态栏右滑截图

## 分析对象

- 用户提供 Pro 2.7.6-1：SHA256 `240362fc1846f697025122e4788d04bbd1920b8f5102bcfc5642a9a14b62837a`，与作者源索引一致。
- 先前下载的免费版 1.3.5：用于完整追踪挂载、区域判断及截图调用。
- 本次从作者源下载免费版 1.3.7：SHA256 `aba10272daaa5d69bf47f54ca21997f4dd74995b8ae88dc08cd8bdf2f0957ad7`，与源索引一致。
- 源：https://lclrc.github.io/repo/Packages 。源中免费版名称为 SquidGesture，不是 SquidGesturePro。

以下地址均为各自 Mach-O 的 arm64e 切片虚拟地址，不是文件偏移。

## 有证据的路径

免费版 1.3.5：

- `_UIStatusBar initWithStyle:` 替换实现 `0xe2ac`。
- `0xe4a8–0xe4e0`：分配 UISwipeGestureRecognizer，target 为状态栏，action 为 `sg_rightSwipe:`，direction=1（右），touches=1，addGestureRecognizer。
- `sg_rightSwipe:` 在 `0xec68`；先检查 state=3，`0xed5c` 调用 locationInView，比较横坐标与区域边界，再调用 sg_doAction。
- `SGActionStore sg_systemScreenshot` 在 `0x5454`；触觉反馈后，向保存的 SpringBoard 对象发送 takeScreenshot。

免费版 1.3.7：

- `SGActionStore sg_systemScreenshot` 在 `0xac6c`；`0xac7c` selector ref `0x4c6c0` 为触觉反馈；`0xac88` 读取 SpringBoard 全局对象；`0xac90` selector ref `0x4c8c0` 为 takeScreenshot。
- `0x3ce70–0x3cec8` 确认相同右滑挂载片段，action selector ref `0x4c748` 为 sg_rightSwipe，direction=1，touches=1，然后添加到视图。
- 1.3.7 存在控制流混淆，本次没有完整还原所有区域/设置分支。

Pro 2.7.6-1 的动作方法名和控制流混淆明显，本次读取了 ObjC 元数据并确认大量混淆方法。
没有完整恢复它的状态栏实现；不能将免费版路径说成 Pro 2.7.6 的逐行源码。

## 独立实现的差异

- 新实现只 hook `_UIStatusBar didMoveToWindow`，不 hook initWithStyle；挂载时保留原方法。
- 标准 UISwipeGestureRecognizer + 独立 NSObject 代理/target，无手势子类、无新增系统类方法。
- 以起点位于右侧三分之一区域为条件；原免费版 handler 用识别时的位置比较其可配置区域。
- 从 UIApplication.sharedApplication 获取当前 SpringBoard 对象，不增加启动方法 hook。
- main queue 异步调用 takeScreenshot；先检查类、方法存在及无参数 void 返回签名。
- 不移植启动校验、激活、动作流、截图覆盖层或其他手势。

TapFlash 4.1.2 只有 AVFlashlight/init 和 SBLockHardwareButton/doublePress/triplePress，
与新插件 hook 不重合。仓库中独立目录和构建工作流，不修改 TapFlash 原文件。

## 不能下的结论

没有上次白苹果的崩溃日志，不能认定其根因，也不能保证这个版本在设备上稳定。
异常捕获不处理 EXC_BAD_ACCESS、进程被杀、死锁及 watchdog。
边界检查只验证区域数学；云端编译只验证编译/链接。屏幕截图、系统手势竞争和锁屏行为仍需设备验证。
