# 「想看就看」电视直播 App

TCL 55 T7H 专用电视直播应用 MVP 版本。

## 环境依赖

所有开发工具已安装在外置硬盘 `/Volumes/MSI M470 PRO 800G/`：

| 组件 | 路径 | 版本 |
|------|------|------|
| Flutter SDK | `/Volumes/MSI M470 PRO 800G/flutter` | 3.38.10 |
| Android SDK | `/Volumes/MSI M470 PRO 800G/Android/sdk` | API 36 |
| 项目代码 | `/Volumes/MSI M470 PRO 800G/codex/tv app` | v0.1 |

## 日常开发：如何打开和运行

### 1. 设置终端环境变量

每次打开终端后，先执行：

```bash
export FLUTTER_ROOT="/Volumes/MSI M470 PRO 800G/flutter"
export PATH="$FLUTTER_ROOT/bin:$PATH"
export PUB_HOSTED_URL="https://pub.flutter-io.cn"
export FLUTTER_STORAGE_BASE_URL="https://storage.flutter-io.cn"
export ANDROID_HOME="/Volumes/MSI M470 PRO 800G/Android/sdk"
export ANDROID_SDK_ROOT="$ANDROID_HOME"
```

为了方便，可以把这些加到 `~/.zshrc` 文件末尾。

### 2. 用 Android Studio 打开项目

- 打开 Android Studio
- 选择「Open」→ 导航到 `/Volumes/MSI M470 PRO 800G/codex/tv app`
- Android Studio 会自动识别为 Flutter 项目

### 3. 编译 APK

在项目目录下执行：

```bash
cd "/Volumes/MSI M470 PRO 800G/codex/tv app"
flutter build apk --debug
```

生成的 APK 在 `build/app/outputs/flutter-apk/app-debug.apk`

### 4. 安装到电视

**方式一：U 盘安装（推荐）**

- 把 `app-debug.apk` 拷贝到 U 盘
- 插入电视 USB 口
- 用电视的文件管理器打开安装
- 如果提示「未知来源」，去设置里开启

**方式二：ADB 远程安装**

```bash
# 先在电视上开启「开发者选项」→「ADB 调试」
adb connect <电视的IP地址>
adb install build/app/outputs/flutter-apk/app-debug.apk
```

## 项目结构

```
lib/
  main.dart                      # 应用入口
  models/
    channel.dart                 # 频道数据模型
    signal_source.dart           # 信号源数据模型
  services/
    m3u_parser.dart              # M3U 播放列表解析器
    database_service.dart        # SQLite 本地数据库
    channel_manager.dart         # 频道管理（导入、分类、查询）
    signal_checker.dart          # 信号源可用性检测
    http_server.dart             # 内嵌 HTTP 服务（二维码更新）
  screens/
    channel_list_screen.dart     # 频道列表主页
    player_screen.dart           # 全屏播放器
  widgets/
    channel_card.dart            # 频道卡片组件
    category_tabs.dart           # 分类标签栏
```

## 当前完成情况

| 阶段 | 状态 |
|------|------|
| 1. 工程搭建 | ✅ 已完成 |
| 2. M3U 解析 | ✅ 服务代码已写，待接入实际源 |
| 3. 频道列表 UI | ✅ 框架已搭建 |
| 4. 播放器集成 | ✅ media_kit 已接入 |
| 5. 信号源检测 | ✅ 并发检测逻辑已实现 |
| 6. 自动更新 | 🔲 待开发（HTTP 服务 + 二维码） |
| 7. TV 适配 | 🔲 待真机测试 |
| 8. 打包发布 | 🔲 待完成 |
