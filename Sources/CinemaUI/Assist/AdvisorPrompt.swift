import Foundation
import SonyCameraKit

/// The text the on-device model sees. Plain sentences, because the model's language check rejects
/// terse key=value dumps as "unsupported language"; the model never sees pixels.
public enum AdvisorPrompt {
    public static let instructions = """
    你是电影片场的第一摄影助理，正在查看 Sony α6400 的监视器。你会收到相机设置、实时画面测量值和问题提示，但看不到画面本身。请为每条问题写一句简短提示，直接告诉摄影师画面的问题及其影响。不要重复数值，不要照抄问题文本，必须原样保留对应的问题编号。不要建议参数值或设置名称；解决方案会单独附上。语气示例：人脸陷入阴影。肤色过曝，收一点。焦点落在主体后方。快门太快，运动出现频闪。地平线向左倾斜。头顶空间不足，镜头抬高一些。
    """

    public static func build(findings: [Finding], measurements m: SceneMeasurements, state s: CameraState,
                             profile: PictureProfile, projectFPS: Int) -> String {
        var lines: [String] = []
        let angle = ShutterAngle.label(speed: s.shutterSpeed, fps: projectFPS)
        lines.append("相机：\(localizedCameraValue(s.exposureMode ?? "未知"))模式，快门 \(s.shutterSpeed ?? "未知")（\(projectFPS) fps 下 \(angle)°），"
                     + "光圈 F\(s.fNumber ?? "未知")，EI \(s.iso ?? "未知")，曝光补偿 \(s.exposureCompensation?.label ?? "0")，"
                     + "白平衡 \(localizedCameraValue(s.whiteBalanceMode ?? "未知"))，对焦 \(localizedCameraValue(s.focusMode ?? "未知"))，状态 \(localizedCameraValue(s.focusStatus ?? "未知")），"
                     + "图片配置文件 \(profile.short)。")
        var frame = "画面：平均亮度 \(Int(m.meanLuma.rounded())) / 100，\(Int((m.whiteClip * 100).rounded()))% 高光溢出，"
                  + "\(Int((m.blackClip * 100).rounded()))% 暗部为纯黑，对焦区域清晰度 \(String(format: "%.2f", m.afSharpness)) / 1"
        if let f = m.faces.first {
            frame += "，检测到 \(m.faces.count) 张人脸，最大人脸亮度 \(Int(f.luma.rounded()))，位置约为 x \(String(format: "%.2f", f.center.x))、y \(String(format: "%.2f", f.center.y))"
        } else { frame += "，未检测到人脸" }
        if let h = m.horizonDegrees { frame += "，地平线倾斜 \(String(format: "%.1f", h))°" }
        lines.append(frame + "。")
        lines.append("问题提示：")
        for f in findings { lines.append("[\(f.id)] \(f.fact)：\(f.detail)") }
        return lines.joined(separator: "\n")
    }
}

/// Whether the on-device model can be used right now, and why not.
public enum ShotAdvisorAvailability: Equatable, Sendable {
    case available, appleIntelligenceOff, modelNotReady, deviceNotEligible, needsOS26

    public var reason: String? {
        switch self {
        case .available: return nil
        case .appleIntelligenceOff: return "Apple Intelligence 已在系统设置中关闭"
        case .modelNotReady: return "Apple Intelligence 模型尚未就绪"
        case .deviceNotEligible: return "此设备不支持 Apple Intelligence"
        case .needsOS26: return "需要 macOS 26 或更新版本"
        }
    }

    public static var current: ShotAdvisorAvailability {
        #if canImport(FoundationModels)
        if #available(macOS 26, iOS 26, *) { return ShotAdvisor.availability }
        #endif
        return .needsOS26
    }
}
