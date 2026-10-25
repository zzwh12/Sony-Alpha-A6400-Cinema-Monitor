import SwiftUI
import CoreGraphics
import SonyCameraKit

/// Chinese labels for camera values; commands continue to use the original protocol values.
public func localizedCameraValue(_ value: String) -> String {
    switch value {
    case "Manual", "Movie M": return "手动"
    case "Aperture", "Movie A": return "光圈优先"
    case "Shutter", "Movie S": return "快门优先"
    case "Program Auto", "Movie P": return "程序自动"
    case "Intelligent Auto", "Movie Auto": return "智能自动"
    case "Superior Auto": return "增强自动"
    case "Auto WB": return "自动白平衡"
    case "Daylight": return "日光"
    case "Shade": return "阴影"
    case "Cloudy": return "阴天"
    case "Incandescent": return "白炽灯"
    case "Flash": return "闪光灯"
    case "Color Temperature": return "色温"
    case "Underwater Auto": return "水下自动"
    case "Custom 1": return "自定义 1"
    case "Focused": return "已合焦"
    case "Failed": return "对焦失败"
    case "Focusing": return "正在对焦"
    case "VIDEO": return "视频"
    case "PHOTO": return "照片"
    case "IN FOCUS": return "对焦准确"
    case "SOFT": return "轻微软焦"
    case "MISSED": return "对焦失误"
    case "USB": return "USB"
    case "WI-FI": return "Wi-Fi"
    case "BRIDGE": return "桥接"
    case "CAMERA BRIDGE": return "Mac 桥接"
    default: return value
    }
}

public func localizedHUDLabel(_ value: String) -> String {
    switch value {
    case "FPS": return "帧率"
    case "SHUTTER": return "快门"
    case "IRIS": return "光圈"
    case "EI", "ISO": return "感光度"
    case "EV": return "曝光"
    case "WB": return "白平衡"
    case "FOCUS": return "对焦"
    default: return value
    }
}

public func localizedCameraMessage(_ message: String) -> String {
    let prefixes: [(String, String)] = [
        ("Reconnecting: ", "正在重新连接："), ("Lost connection: ", "连接已断开："),
        ("Bridge: ", "桥接错误："), ("Touch AF: ", "触屏对焦："),
        ("Autofocus: ", "自动对焦："), ("Setting: ", "相机设置："),
        ("Focus: ", "对焦："), ("Zoom: ", "变焦："),
        ("Shutter: ", "快门："), ("Iris: ", "光圈："), ("ISO: ", "感光度："),
        ("Mode: ", "模式："), ("Shoot mode: ", "拍摄模式："),
        ("WB: ", "白平衡："), ("EV: ", "曝光补偿："),
        ("AF: ", "自动对焦："), ("Shoot: ", "拍摄："),
        ("REC: ", "开始录制："), ("Stop REC: ", "停止录制："),
        ("ONE SHOT: ", "单次拍摄："), ("AEL: ", "曝光锁："),
        ("Still size: ", "照片尺寸："), ("Movie quality: ", "视频画质："),
        ("Movie format: ", "视频格式："),
    ]
    for (prefix, translation) in prefixes where message.hasPrefix(prefix) {
        return translation + String(message.dropFirst(prefix.count))
    }
    switch message {
    case "stream ended": return "视频流已结束"
    case "cancelled": return "操作已取消"
    case "no camera": return "未连接相机"
    default: return message
    }
}

/// Aspect crop applied to the live view. Cropping to a cinema ratio lets the frame fill an
/// ultrawide (21:9) monitor edge to edge instead of letterboxing a 3:2 or 16:9 feed.
public enum CropRatio: String, CaseIterable, Identifiable {
    case native, r16x9, r185, r200, r235, r239, r1x1, r4x5, r9x16
    public var id: String { rawValue }
    public var value: Double? {
        switch self {
        case .native: return nil
        case .r16x9: return 16.0 / 9.0
        case .r185: return 1.85
        case .r200: return 2.0
        case .r235: return 2.35
        case .r239: return 2.39
        case .r1x1: return 1.0
        case .r4x5: return 0.8
        case .r9x16: return 9.0 / 16.0
        }
    }
    public var label: String {
        switch self {
        case .native: return "NATIVE"
        case .r16x9: return "16:9"
        case .r185: return "1.85"
        case .r200: return "2.00"
        case .r235: return "2.35"
        case .r239: return "2.39"
        case .r1x1: return "1:1"
        case .r4x5: return "4:5"
        case .r9x16: return "9:16"
        }
    }
    public var menuTitle: String {
        switch self {
        case .native: return "原始画幅（不裁切）"
        case .r16x9: return "16:9"
        case .r185: return "1.85:1 宽银幕"
        case .r200: return "2.00:1 Univisium"
        case .r235: return "2.35:1 变形宽银幕"
        case .r239: return "2.39:1 变形宽银幕"
        case .r1x1: return "1:1 正方形"
        case .r4x5: return "4:5 竖幅"
        case .r9x16: return "9:16 竖屏（短视频）"
        }
    }
    public var next: CropRatio { let all = Self.allCases; return all[(all.firstIndex(of: self)! + 1) % all.count] }
}

@Observable
public final class OverlaySettings {
    public init() {}
    public var grid = true
    public var frameGuides = false
    public var centerMarker = true
    public var peaking = false
    public var zebra = false
    public var hideHUD = false
    public var zebraLevel: Double = 0.95
    public var crop: CropRatio = .native
    /// MetalFX spatial upscaling of the live view to the display resolution.
    public var enhanced = false
    /// Optional detail-recovery sharpening after upscaling (off = faithful).
    public var detail = false
    /// How the camera's feed is interpreted before macOS converts it to the display's own profile.
    public var feedColorSpace: FeedColorSpace = .sRGB
    public var falseColor = false
    public var waveform = false
    /// Project frame rate, used for shutter angle and the timecode frame counter.
    public var projectFPS = 24
    /// Picture profile set on the camera body (declared here so LOG/709 can apply the right conversion).
    public var profile: PictureProfile = .standard
    /// Apply the display LUT (709 view) instead of showing the log feed.
    public var lutOn = true
    public var customLUT: (data: Data, dimension: Int)?
    public var customLUTName: String?
    public var scope: ScopeKind = .none
    /// 2× centre magnification for focus checks.
    public var magnify = false
    public var showMenu = false
    public var cameraIndex = "A"
    public var reel = 1
    /// Display rotation in degrees for a camera mounted sideways (vertical shooting).
    public var rotation = 0
    public var modeResolver = ShootingModeResolver()
    public var shootingMode: ShootingMode { modeResolver.mode }
    public var reviewShowsRAW = false
    /// Guides (mobile guides sheet; the Mac keeps its own defaults).
    public var guideRatio: FrameGuideRatio = .r239
    public var safeAreas = false
    public var diagonals = false
    public var peakingColor: PeakingColor = .red
    public var showSharpnessMeter = true
    /// Display-only mist look (0 off, 0.5 MIST1, 1 MIST2): highlights halo and skin softens on the
    /// monitor; the camera records clean. Remembered across launches.
    public var mist: Double = UserDefaults.standard.double(forKey: "mist") {
        didSet { UserDefaults.standard.set(mist, forKey: "mist") }
    }
    /// Shot assist advisories over the picture (Mac video monitor). Remembered across launches.
    public var assist: Bool = UserDefaults.standard.object(forKey: "assist") as? Bool ?? true {
        didSet { UserDefaults.standard.set(assist, forKey: "assist") }
    }

    /// The LUT that should be applied to the feed right now, if any.
    public var activeLUT: (data: Data, dimension: Int)? {
        guard lutOn else { return nil }
        if let customLUT { return customLUT }
        if let d = LUTBuilder.cube(for: profile) { return (d, LUTBuilder.dimension) }
        return nil
    }
}

/// Colour interpretation of the live view. The pixel values never change; the tag tells macOS which
/// transfer curve and primaries they are in, and macOS converts to the connected display's ICC profile.
public enum FeedColorSpace: String, CaseIterable, Identifiable {
    case sRGB = "sRGB（相机 JPEG，与相机屏幕一致）"
    case rec709 = "Rec.709 视频（BT.1886 伽马，调色监视器观感）"
    public var id: String { rawValue }
    public var short: String { self == .sRGB ? "sRGB" : "709" }
    public var cgColorSpace: CGColorSpace {
        self == .sRGB ? CGColorSpace(name: CGColorSpace.sRGB)! : CGColorSpace(name: CGColorSpace.itur_709)!
    }
}

public enum ScopeKind: String, CaseIterable, Identifiable {
    case none = "OFF", waveform = "WFM", parade = "RGB", histogram = "HIST", vector = "VEC"
    public var id: String { rawValue }
    public var next: ScopeKind { let a = Self.allCases; return a[(a.firstIndex(of: self)! + 1) % a.count] }
    public var title: String {
        switch self { case .none: return "关闭"; case .waveform: return "亮度波形"; case .parade: return "RGB 分量"; case .histogram: return "RGB 直方图"; case .vector: return "矢量示波器" }
    }
}

