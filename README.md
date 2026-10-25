# CinemaHUD

> **简体中文汉化版**
>
>上游项目:[shivvyas2/Sony-Alpha-A6400-Cinema-Monitor](https://github.com/shivvyas2/Sony-Alpha-A6400-Cinema-Monitor)

![CinemaHUD 在 MacBook Pro、iPhone 和 iPad 上的监看画面，显示电影风格取景器和实时曝光信息](docs/images/cinemahud-hero.jpg)

CinemaHUD 是适用于 macOS、iPhone 和 iPad 的 Sony α 相机远程监视器。它将实时取景画面与电影风格 HUD 结合，可查看快门、光圈、ISO、白平衡、曝光补偿和对焦状态，并支持触屏对焦、拍照、视频录制、峰值对焦、斑马纹、伪色、构图辅助线和电影画幅裁切。

应用通过 **USB** 或相机自带的 **Wi-Fi** 连接相机。macOS 版可直接通过 IOUSBHost 与 Sony PTP 扩展通信，也支持 Sony Camera Remote API；无需安装 Sony 驱动或配套软件。

## 连接相机

### USB（推荐，延迟最低）

1. 在相机菜单中将“USB 连接”设为 **PC Remote（电脑遥控）**。
2. 将模式转盘设为 M 或视频 M。
3. 连接 USB 线缆，在 CinemaHUD 中点按“连接 USB”。

如果相机被识别为磁盘，请先在相机上退出 Mass Storage（大容量存储）模式。macOS 的图像捕捉服务可能会占用 PTP 相机；CinemaHUD 在连接时会尝试释放设备。如果 Imaging Edge、Capture One 等应用正在使用相机，请先退出该应用。

### Wi-Fi

1. 在相机中开启“用智能手机控制”，然后进入连接界面。
2. Mac 或 iPhone/iPad 加入相机显示的 Wi-Fi 网络。
3. 点按“搜索”。如果没有找到相机，可输入 `192.168.122.1:8080` 后选择“连接”。

Wi-Fi 连接支持触屏对焦。相机通常会带来更高延迟和较低帧率，但应用会优先显示最新画面，并在连接中断后自动尝试恢复。

macOS 安装包为临时签名，未经公证。首次打开时，如果系统阻止启动，请在 Finder 中右键点按应用并选择“打开”，或前往“系统设置 → 隐私与安全性”选择“仍要打开”。首次搜索相机时，macOS 还会请求本地网络访问权限，请选择允许。

### iPhone / iPad 的 Mac 桥接

iPhone 和 iPad 无法通过 USB 直接连接相机。可以先用 USB 将相机连接到 Mac，再在 Mac 的“相机”菜单中开启“共享相机到 iPhone / iPad”。iOS 版会在本地网络中发现这台 Mac，并使用它转发的画面、相机状态和控制命令。

## 拍摄与监看

### 视频模式

顶部信息栏显示项目帧率、快门角度与快门速度、光圈、ISO、曝光补偿、白平衡和对焦状态。底部信息栏显示镜头焦距、电量、卷号、片段号、录制状态、存储卡余量与时间码。侧边工具可切换构图辅助、伪色、峰值对焦、斑马纹、示波器、放大和图片配置文件预览。

### 照片模式

将相机转盘切换到照片档位，应用会切换到照片监看界面（也可按 Tab 暂时切换）。拍摄的 JPEG 和 RAW 文件会传输到 Mac，并保存到 `~/Pictures/CinemaHUD/<日期>/`。相机需设为 RAW+JPEG，并将静态影像保存位置设为 PC 或 PC+Camera。Wi-Fi 遥控接口只会传送 JPEG。

照片传输完成后会自动进入回看。可在 JPEG 与 RAW 之间切换、放大对焦点、拖动查看画面，并用左右方向键浏览照片；按 Esc 返回实时画面。底部胶片栏会显示当前拍摄会话中的照片。

### 构图辅助

可开启三分网格、中心标记、安全框、对角线和不同画幅的取景框线。裁切会实际缩小监看画面；取景框线只作叠加提示。支持 16:9、1.85:1、2.00:1、2.35:1、2.39:1、1:1、4:5 和 9:16 等比例。相机横向安装时，可旋转画面以便竖屏拍摄。

### 曝光、色彩与 LUT

α6400 不允许通过遥控协议更改图片配置文件，请先在相机机身上选择 PP7、PP8、PP9 或 PP10，再在 CinemaHUD 中指定相同配置。LOG/709 预览可将 S-Log2、S-Log3 或 HLG 画面转换为 Rec.709。也可载入自定义 `.cube` 3D LUT。示波器会读取 LUT 处理后的画面。

应用会按 sRGB 或 Rec.709 标记相机 JPEG，并由 macOS 根据外接显示器的 ICC 配置进行色彩转换。切换预览 LUT、降噪或运动平滑只改变监看效果，不会修改相机实际录制的素材。

### 画面增强

- **增强放大**使用 MetalFX 在 GPU 上放大实时画面；不支持 MetalFX 时会改用 Lanczos。
- **细节恢复**可在放大后进行锐化。
- **动态平滑**可合成帧间画面，将显示帧率提高到 ×2、×4 或 ×8。因为需要等待下一帧，会增加约一帧延迟。
- **实时降噪**通过运动补偿融合相邻画面，可选轻度或强度两档。
- **柔光效果**只影响监视器预览，为高光添加光晕并柔化肤色，不影响相机录制内容。

这些处理不会凭空增加相机传感器的细节；严肃对焦时建议关闭动态平滑和降噪。

相机实时画面为 1024×680 JPEG。Wi-Fi 通常有约 100–300 毫秒延迟，帧率也会低于 USB；建议在距离相机较近且无遮挡的位置使用。画面处理主要由 GPU 完成，实时示波器读取缩小后的画面区域。

### 拍摄辅助

macOS 版可分析人脸曝光、对焦、剪切高光、地平线和构图，并给出可一键应用的建议。运行 macOS 26 且支持 Apple Intelligence 时，可由本机模型简化建议措辞；所有画面分析均在 Mac 本地完成。

## 现场音频（macOS）

CinemaHUD 可从音频接口录制 WAV，并通过 MIDI 时间码和 MIDI 机器控制与 Logic 同步。使用“同步素材”可将 WAV 与相机片段对齐，并导出供 Final Cut Pro 使用的 XML。相机片段可从 SD 卡的 CLIP 文件夹导入。

## 控制快捷键（macOS）

| 操作 | 快捷键 |
|---|---|
| 自动对焦 / 自动曝光锁定 | 空格 |
| 拍摄照片 | Return |
| 开始 / 停止视频录制 | R |
| 隐藏 HUD | H |
| 峰值对焦 | P |
| 斑马纹 | Z |
| 伪色 | V |
| 三分网格 | G |
| 取景框线 | F |
| 放大 | X |
| 切换示波器 | W |
| 切换菜单 | N |
| 切换图片配置文件预览 | L |
| 切换动态平滑 | M |
| 切换实时降噪 | D |
| 切换照片 / 视频模式 | Tab |
| 退出照片回看 | Esc |

## 使用 GitHub Actions 构建 iOS IPA

在 GitHub 仓库的 **Actions** 页面运行“构建 iOS 安装包”，或推送到 `main` 分支。工作流会上传名为 `CinemaHUD-iOS-安装包` 的短期构建产物。发布版本时，推送 `v*` 标签（例如 `v2.4.1`）会触发构建，并在成功后自动创建 GitHub Release、附上 IPA 和生成版本说明。

不设置签名密钥时，工作流会生成需要另行签名后才能安装的 IPA。若要自动导出 Ad Hoc 签名安装包，请在仓库的 Actions Secrets 中配置以下四项：

- `APPLE_CERTIFICATE_BASE64`：Apple Distribution `.p12` 证书的 Base64 内容。
- `APPLE_CERTIFICATE_PASSWORD`：该 `.p12` 证书的密码。
- `PROVISIONING_PROFILE_BASE64`：适用于 `com.shivvyas.cinemahud.mobile` 的 Ad Hoc 描述文件 Base64 内容。
- `APPLE_TEAM_ID`：Apple Developer 团队 ID。

Ad Hoc 描述文件必须包含准备安装应用的设备。

## 构建 macOS 版

需要 macOS 14 或更新版本、Xcode 15 或更新版本，以及 Swift 5.9 或更新版本。

```sh
swift test                 # 运行协议层单元测试
./scripts/build-dmg.sh     # 生成 build/CinemaHUD.app 和版本化 DMG
```

iOS 工程由 XcodeGen 根据 `iOS/project.yml` 生成。可在 Xcode 中打开 `iOS/CinemaHUDMobile.xcodeproj`，选择模拟器或设备并运行；在真机上运行时，需要在“签名与功能”中选择开发团队。

## 相机诊断工具

已连接相机时可运行下列命令检查 Wi-Fi API 或 USB PTP 通信：

```sh
tools/probe.sh
swift run usbprobe
swift run usbprobe --set shutter=1/50 --rec --af --shoot --watch
PTP_DEBUG=1 swift run usbprobe
```

桥接服务使用本地 HTTP 端口 8899：`GET /state` 读取状态，`GET /events` 接收状态变化，`GET /stream` 接收实时 MJPEG 画面，`POST /cmd` 发送控制命令。

## 无相机开发

`tools/camerasim.py` 可模拟 α6400 的网络 API 和实时画面，需要 Python 3 与 Pillow：

```sh
python3 tools/camerasim.py
CINEMAHUD_ADDRESS=127.0.0.1:8080 swift run CinemaHUD
```

模拟器参数：`--stills` 模拟照片档位，`--pz` 模拟电动变焦镜头，`--photo photo.jpg` 使用指定图片作为实时画面。

## 项目结构

- `Sources/SonyCameraKit`：Sony 相机协议、USB / Wi-Fi 传输和会话管理。
- `Sources/CinemaUI`：Mac 与 iOS 共用的 SwiftUI 监看界面和画面处理。
- `Sources/CinemaAudio`：现场录音、音频同步及文件导出。
- `Sources/CinemaHUD`：macOS 应用入口、菜单和快捷键。
- `Sources/usbprobe`：USB 相机诊断命令行工具。
- `iOS/`：iPhone / iPad 应用工程。
- `Tests/`：协议、相机状态、图像和音频处理测试。
- `tools/camerasim.py`：网络相机模拟器。
- `docs/superpowers/specs/`：功能设计文档。

## 当前验证状态

USB 连接已在真实 α6400 上验证。Wi-Fi 路径按 Sony Camera Remote API 实现，并已通过模拟器端到端验证，尚未在相机机身上完成验证。照片模式和现场音频中的部分流程目前仍待真实设备验证。

α6400 上的 USB 实时取景、相机控制、电池状态和视频录制已经验证。照片传输、照片回看与清晰度判断目前已在模拟器上测试，仍需相机实测。现场音频到 Logic、真实 SD 卡素材同步和 Final Cut Pro XML 导入流程也仍待完整实测。
