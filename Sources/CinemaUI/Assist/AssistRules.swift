import Foundation
import CoreGraphics
import SonyCameraKit

/// Turns measurements plus camera state into findings. Pure; every fix is a command the connected
/// camera advertises. Order is priority order; at most four are returned.
public enum AssistRules {
    public static let stopThreshold = 0.66
    public static let maxFindings = 4

    /// Skin-tone target (0–100) for the camera's picture profile, measured before the display LUT.
    public static func skinTarget(for profile: PictureProfile) -> Double {
        switch profile {
        case .standard: return 55
        case .pp7: return 32
        case .pp8, .pp9: return 41
        case .pp10: return 45
        }
    }

    /// "1 STOP", "1.3 STOPS", "0.7 STOP": magnitude rounded to the nearest third.
    public static func stopsLabel(_ stops: Double) -> String {
        let thirds = (abs(stops) * 3).rounded() / 3
        if abs(thirds - 1) < 0.01 { return "1 档" }
        let text = String(format: "%.1f", thirds)
        return "\(text) 档"
    }

    public static func findings(_ m: SceneMeasurements, state s: CameraState, profile: PictureProfile,
                                projectFPS: Int, shootingMode: ShootingMode, mist: Double = 0) -> [Finding] {
        var out: [Finding] = []
        let face = m.faces.first
        var faceFinding = false

        // Exposure on the face.
        if let face, face.luma > 0 {
            let target = skinTarget(for: profile)
            let stops = log2(face.luma / target)
            if abs(stops) >= stopThreshold {
                let under = stops < 0
                out.append(Finding(id: under ? "face-under" : "face-over", kind: .exposure, severity: .warn,
                                   fact: "人脸曝光\(under ? "不足" : "过度") \(stopsLabel(stops))",
                                   detail: String(format: "画面中最大的人脸亮度为 %.0f；%@ 配置文件的肤色目标为 %.0f（相差 %.1f 档，%@）。",
                                                  face.luma, profile.short, target, abs(stops), under ? "偏暗" : "偏亮"),
                                   fix: exposureFix(stops: stops, state: s)))
                faceFinding = true
            }
        }
        if !faceFinding, m.whiteClip >= 0.02 {
            out.append(Finding(id: "highlights-clip", kind: .exposure, severity: .info, fact: "高光溢出",
                               detail: String(format: "%.0f%% 的画面像素已过曝。", m.whiteClip * 100)))
        }
        if !faceFinding, m.blackClip >= 0.10, m.meanLuma < 25 {
            out.append(Finding(id: "shadows-crush", kind: .exposure, severity: .info, fact: "暗部细节丢失",
                               detail: String(format: "%.0f%% 的像素为纯黑，画面平均亮度为 %.0f。", m.blackClip * 100, m.meanLuma)))
        }

        // Focus.
        if let face, m.sharpestScore > 0, face.sharpness < 0.6 * m.sharpestScore,
           hypot(m.sharpestRegion.x - face.center.x, m.sharpestRegion.y - face.center.y) >= 0.15 {
            let fix = s.supports("setTouchAFPosition")
                ? Fix(label: "对焦到人脸", command: .touchAF(x: Double(face.center.x), y: Double(face.center.y))) : nil
            out.append(Finding(id: "focus-missed", kind: .focus, severity: .warn, fact: "焦点未落在主体上",
                               detail: "人脸不够清晰，画面其他区域却更清楚；当前焦点没有落在主体上。", fix: fix))
        }
        if s.focusStatus == "Failed" {
            out.append(Finding(id: "focus-failed", kind: .focus, severity: .warn, fact: "自动对焦失败",
                               detail: "相机报告自动对焦失败。",
                               fix: s.supports("actHalfPressShutter") ? Fix(label: "自动对焦", command: .autofocus) : nil))
        }

        // Settings.
        if shootingMode == .video, let deg = ShutterAngle.degrees(speed: s.shutterSpeed, fps: projectFPS), deg < 150 || deg > 210 {
            var fix: Fix?
            if s.supports("setShutterSpeed"), let best = ShutterAngle.nearest180(candidates: s.shutterSpeedCandidates, fps: projectFPS),
               best != s.shutterSpeed, let cur = s.shutterSpeed {
                fix = Fix(label: "\(cur) → \(best)", command: .setShutterSpeed(best))
            }
            out.append(Finding(id: "shutter-angle", kind: .settings, severity: .info,
                               fact: "快门角度 \(deg > 360 ? "360+" : String(format: "%.0f", deg))°",
                               detail: String(format: "%@ 在 %d fps 下的快门角度为 %.0f°，%@ 180° 标准；%@。", s.shutterSpeed ?? "--", projectFPS, deg,
                                              deg < 180 ? "明显小于" : "明显大于",
                                              deg < 180 ? "运动画面可能显得卡顿并带有频闪" : "运动画面可能出现拖影"),
                               fix: fix))
        }

        // Framing.
        if let h = m.horizonDegrees, abs(h) >= 1.5 {
            out.append(Finding(id: "horizon", kind: .framing, severity: .info, fact: String(format: "地平线偏斜 %.0f°", abs(h)),
                               detail: String(format: "地平线倾斜了 %.1f°。", h)))
        }
        if let face {
            if face.rect.minY < 0.02 {
                out.append(Finding(id: "headroom", kind: .framing, severity: .info, fact: "头顶空间不足",
                                   detail: "人脸已经贴近画面上边缘。"))
            } else if face.center.y > 0.62 {
                out.append(Finding(id: "headroom", kind: .framing, severity: .info, fact: "主体位置偏低",
                                   detail: "主体位于画面下方，上方留白较多。"))
            }
        }
        // Look: only when nothing is wrong, in video, with a person in frame. Suggestions toward a
        // softer, more cinematic image; the mist one is a monitor-side preview, not a camera change.
        if shootingMode == .video, let face, !out.contains(where: { $0.severity == .warn }) {
            if let cur = s.fNumber, let f = Double(cur), f >= 5.6, s.supports("setFNumber"),
               let widest = s.fNumberCandidates.compactMap({ c in Double(c).map { (c, $0) } }).min(by: { $0.1 < $1.1 }), widest.1 < f {
                out.append(Finding(id: "dof", kind: .look, severity: .info, fact: "开大光圈，柔化背景",
                                   detail: String(format: "画面中有人物时，F%@ 光圈会让背景保持清晰；更大的光圈能营造更浅、更具电影感的景深。", cur),
                                   fix: Fix(label: "F\(cur) → F\(widest.0)", command: .setFNumber(widest.0))))
            }
            if mist == 0 {
                out.append(Finding(id: "mist", kind: .look, severity: .info, fact: "试试柔光效果",
                                   detail: "当前画面干净锐利；监视器的柔光效果会为高光添加光晕、柔化肤色，模拟柔焦滤镜的观感。",
                                   fix: Fix(label: "开启柔光", command: .monitorMist(0.5))))
            }
            _ = face
        }
        return Array(out.prefix(maxFindings))
    }

    /// ISO in manual modes, exposure compensation otherwise. nil when the camera cannot do it or is already there.
    static func exposureFix(stops: Double, state s: CameraState) -> Fix? {
        let mode = s.exposureMode ?? ""
        let manual = mode.hasPrefix("Manual") || mode == "Movie M"
        if manual {
            guard s.supports("setIsoSpeedRate"), let cur = s.iso, let curISO = Double(cur) else { return nil }
            let wanted = curISO * pow(2, -stops)
            let numeric = s.isoCandidates.compactMap { c in Double(c).map { (c, $0) } }
            guard let best = numeric.min(by: { abs(log2($0.1 / wanted)) < abs(log2($1.1 / wanted)) })?.0, best != cur else { return nil }
            return Fix(label: "感光度 \(cur) → \(best)", command: .setISO(best))
        }
        guard s.supports("setExposureCompensation"), let ev = s.exposureCompensation else { return nil }
        let delta = Int((-stops / ev.stepEV).rounded())
        let next = max(ev.minIndex, min(ev.maxIndex, ev.index + delta))
        guard next != ev.index else { return nil }
        func label(_ i: Int) -> String {
            let v = Double(i) * ev.stepEV
            return abs(v) < 0.01 ? "0" : String(format: "%@%.1f", v > 0 ? "+" : "", v)
        }
        return Fix(label: "曝光 \(label(ev.index)) → \(label(next))", command: .setExposureCompensation(index: next))
    }
}
