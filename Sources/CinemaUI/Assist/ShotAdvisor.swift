#if canImport(FoundationModels)
import Foundation
import FoundationModels

@available(macOS 26, iOS 26, *)
@Generable
struct AssistAdviceLine {
    @Guide(description: "此行所解释问题的编号，必须与方括号中的编号完全一致")
    var finding: String
    @Guide(description: "用三到六个词简短指出问题，像摄影助理现场提醒；不要写数字或设置项")
    var text: String
}

@available(macOS 26, iOS 26, *)
@Generable
struct AssistAdvice {
    @Guide(description: "每个问题写一行，按重要程度排序", .maximumCount(2))
    var lines: [AssistAdviceLine]
}

/// Phrases findings with Apple's on-device model. One fresh session per call keeps the small
/// context from filling; every failure returns nil and the HUD falls back to the findings' facts.
@available(macOS 26, iOS 26, *)
public enum ShotAdvisor {
    static var availability: ShotAdvisorAvailability {
        switch SystemLanguageModel.default.availability {
        case .available: return .available
        case .unavailable(.appleIntelligenceNotEnabled): return .appleIntelligenceOff
        case .unavailable(.modelNotReady): return .modelNotReady
        case .unavailable: return .deviceNotEligible
        }
    }

    public static func prewarm() {
        guard availability == .available else { return }
        LanguageModelSession(instructions: AdvisorPrompt.instructions).prewarm()
    }

    /// nil when unavailable, on any error, or after `timeout` seconds.
    public static func advise(prompt: String, timeout: TimeInterval = 2) async -> [(finding: String, text: String)]? {
        guard availability == .available else { return nil }
        let session = LanguageModelSession(instructions: AdvisorPrompt.instructions)
        return await withTaskGroup(of: [(finding: String, text: String)]?.self) { group in
            group.addTask {
                do {
                    let r = try await session.respond(to: prompt, generating: AssistAdvice.self)
                    return r.content.lines.map { (finding: $0.finding, text: $0.text) }
                } catch { return nil }
            }
            group.addTask { try? await Task.sleep(for: .seconds(timeout)); return nil }
            let first = await group.next() ?? nil
            group.cancelAll()
            return first
        }
    }
}
#endif
