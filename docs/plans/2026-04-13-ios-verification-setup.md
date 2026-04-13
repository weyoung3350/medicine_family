# iPad 验证环境准备清单

> 目标：在这台 Mac 上准备 Flutter iPad 验证环境。  
> 当前状态：Flutter SDK 未能通过 Homebrew 下载完成，Xcode 未安装，仅有 Command Line Tools。

## 1. 当前阻塞

### 1.1 Flutter SDK
- `flutter` 当前不在 PATH
- `brew install --cask flutter` 在下载阶段失败
- 失败原因是 `storage.googleapis.com` 连接错误

### 1.2 Xcode
- 当前 `xcodebuild -version` 指向的是 Command Line Tools
- 没有检测到完整的 Xcode.app
- 没有 Xcode，就无法为 iPad 真机做 iOS 构建和签名

## 2. 先决条件

### 必须具备
- macOS
- 完整 Xcode.app
- Flutter SDK
- CocoaPods
- 一根可用的数据线
- iPad 已解锁并完成“信任此电脑”

### 建议的验证对象
- iPad 作为主验证设备
- Android 只做代码兼容，不要求实机

## 3. 建议操作顺序

### 第一步：安装 Xcode
1. 从 App Store 安装 Xcode
2. 打开一次 Xcode 完成组件安装
3. 执行：

```bash
sudo xcode-select -s /Applications/Xcode.app/Contents/Developer
sudo xcodebuild -runFirstLaunch
```

4. 再确认：

```bash
xcodebuild -version
```

### 第二步：安装 Flutter
优先方案：
1. 用 Homebrew 安装

```bash
brew install --cask flutter
```

如果下载仍失败，改用 Flutter 官方镜像或手动下载安装到固定目录，再把 `bin` 加入 PATH。

### 第三步：确认 Flutter 可用

```bash
flutter --version
flutter doctor -v
```

### 第四步：安装 iOS 依赖
在项目里执行：

```bash
cd packages/mobile
flutter pub get
cd ios
pod install
```

### 第五步：确认 iPad 连接

```bash
flutter devices
```

如果看不到 iPad：
- 先解锁 iPad
- 确认“信任此电脑”
- 确认 iPad 已开启开发者模式
- 重新插线

### 第六步：运行到 iPad

```bash
cd packages/mobile
flutter run -d <device_id>
```

## 4. 验证重点

- 登录页是否正常
- 首页底部导航是否正常
- 今日服药页是否在 iPad 上排版稳定
- 药箱页拍照/上传入口是否可用
- AI 页面输入框和消息列表是否正常
- 字体、按钮、间距是否适合老人使用

## 5. 当前可先做的准备

- 保持后端 Python 服务运行在 `http://localhost:3000`
- 保持 Web 服务运行在 `http://localhost:5173`
- 保持种子数据可用，方便 iPad 上验证登录后流程

## 6. 如果 Flutter 继续下载失败

可选替代方案：
- 使用官方镜像源
- 手动下载安装到固定目录
- 通过 `flutter` 命令所在目录临时加入 PATH

建议的环境变量：

```bash
export FLUTTER_STORAGE_BASE_URL=https://storage.flutter-io.cn
export PUB_HOSTED_URL=https://pub.flutter-io.cn
```

## 7. 结论

目前这台 Mac 还没有准备到可以直接在 iPad 上跑 Flutter App 的程度。  
阻塞点是：
- Flutter SDK 下载失败
- Xcode 未安装

先补齐这两项，后面才能正式进入 iPad 真机验证。

