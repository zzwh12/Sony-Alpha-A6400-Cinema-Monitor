import XCTest
import CoreGraphics
@testable import CinemaUI
@testable import SonyCameraKit

final class AdvisorPromptTests: XCTestCase {
    func testPromptCarriesStateMeasurementsAndFindingIds() {
        var s = CameraState()
        s.exposureMode = "Manual"; s.shutterSpeed = "1/50"; s.fNumber = "2.8"; s.iso = "800"; s.focusMode = "AF-C"; s.focusStatus = "Focused"
        var m = SceneMeasurements(); m.meanLuma = 42; m.whiteClip = 0.031; m.horizonDegrees = 2.2
        m.faces = [.init(rect: CGRect(x: 0.4, y: 0.2, width: 0.2, height: 0.3), luma: 28, sharpness: 12)]
        let f = [Finding(id: "face-under", kind: .exposure, severity: .warn, fact: "FACE 1 STOP UNDER", detail: "The largest face reads 28; target 55."),
                 Finding(id: "horizon", kind: .framing, severity: .info, fact: "HORIZON 2° OFF", detail: "The horizon is tilted 2.2°.")]
        let p = AdvisorPrompt.build(findings: f, measurements: m, state: s, profile: .standard, projectFPS: 24)
        XCTAssertTrue(p.contains("手动模式"))
        XCTAssertTrue(p.contains("快门 1/50（24 fps 下 172.8°）"))
        XCTAssertTrue(p.contains("光圈 F2.8"))
        XCTAssertTrue(p.contains("EI 800"))
        XCTAssertTrue(p.contains("图片配置文件 STD"))
        XCTAssertTrue(p.contains("检测到 1 张人脸，最大人脸亮度 28"))
        XCTAssertTrue(p.contains("3% 高光溢出"))
        XCTAssertTrue(p.contains("地平线倾斜 2.2°"))
        XCTAssertTrue(p.contains("[face-under] FACE 1 STOP UNDER：The largest face reads 28; target 55."))
        XCTAssertTrue(p.contains("[horizon] HORIZON 2° OFF：The horizon is tilted 2.2°."))
        XCTAssertFalse(p.contains("="), "no key=value tokens: the model's language check rejects them")
        XCTAssertLessThan(p.count, 1200, "prompt must stay small for the on-device context")
    }
    func testInstructionsForbidValues() {
        XCTAssertTrue(AdvisorPrompt.instructions.contains("不要建议参数值"))
    }
    func testAvailabilityReasonIsNilOnlyWhenAvailable() {
        let a = ShotAdvisorAvailability.current
        if case .available = a { XCTAssertNil(a.reason) } else { XCTAssertNotNil(a.reason) }
    }
}
