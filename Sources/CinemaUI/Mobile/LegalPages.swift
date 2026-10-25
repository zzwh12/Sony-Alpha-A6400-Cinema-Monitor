import SwiftUI

/// Privacy Policy and Terms of Use, as plain text with `# ` headings. Shown in Settings and reusable for a store listing.
public enum LegalText {
    public static let developer = "Shiv Vyas"
    public static let contact = "shivvyas0209@gmail.com"
    public static let effectiveDate = "2026年9月15日"

    public struct Paragraph: Identifiable, Equatable {
        public let id: Int
        public let text: String
        public let isHeading: Bool
    }

    public static func paragraphs(_ text: String) -> [Paragraph] {
        text.components(separatedBy: "\n\n").enumerated().map { i, p in
            let t = p.trimmingCharacters(in: .whitespacesAndNewlines)
            return Paragraph(id: i, text: t.hasPrefix("# ") ? String(t.dropFirst(2)) : t, isHeading: t.hasPrefix("# "))
        }
    }

    public static let privacyPolicy = """
    # 隐私政策

    生效日期：\(effectiveDate)。CinemaHUD 由 \(developer) 开发（以下简称“我们”）。

    # 我们收集的信息

    CinemaHUD 不会收集、存储或传输任何个人数据。本应用没有账户、分析工具、广告标识符、崩溃报告服务，也不包含会收集数据的第三方 SDK。

    # 本地网络

    本应用只会与 Sony 相机通信（通过相机自己的 Wi-Fi 网络），或与同一本地网络中运行 CinemaHUD 的 Mac 通信。iOS 请求本地网络权限仅用于此目的。本应用不会向互联网发送数据。

    # 照片与录音

    拍摄期间由相机传输的图像会保存到本设备的 CinemaHUD 文件夹中，可在“文件”App 中查看。文件会留在设备上，直到你将其删除。本应用不会读取照片图库，也不会上传文件。

    # 设置

    监视器偏好设置（辅助线、峰值对焦、LUT、上次连接地址）仅保存在本设备上。

    # 儿童

    CinemaHUD 是一款相机工具，不面向儿童。由于本应用不收集数据，因此不会处理任何人的数据。

    # 政策变更

    如果本政策发生变更，更新后的版本和生效日期会在此处公布。

    # 联系方式

    如有隐私相关问题，请联系：\(contact)。
    """

    public static let termsOfUse = """
    # 使用条款

    生效日期：\(effectiveDate)。使用 CinemaHUD（以下简称“本应用”）即表示你同意本条款。

    # 应用说明

    CinemaHUD 由 \(developer) 提供，是一款用于兼容 Sony 相机的远程监视与控制工具，可配合你自己的设备用于个人或专业用途。

    # 与 Sony 无关联

    CinemaHUD 是独立产品，与 Sony 集团公司及其子公司无关联，也未获其认可或赞助。Sony、Alpha 和 α 是 Sony 集团公司的商标，在此仅用于说明兼容性。

    # 按现状提供

    本应用按“现状”和“可用状态”提供，不提供任何明示或默示的保证，包括适销性、特定用途适用性及不侵权保证。相机行为、连接可靠性和画质取决于你的相机、镜头、固件及网络环境。

    # 用户责任

    你需自行承担通过本应用控制相机的风险。你应对相机设置、拍摄内容、文件备份，以及遵守适用于拍摄和摄影的法律法规负责。

    # 责任限制

    在法律允许的最大范围内，\(developer) 不对因使用本应用造成的素材丢失、错失拍摄、设备损坏或任何间接及后果性损失承担责任。

    # 应用或条款的变更

    随着相机协议变化，各版本功能可能有所调整。更新后的条款及生效日期会在此处公布；条款更新后继续使用本应用，即表示你接受新条款。

    # 联系方式

    如有条款相关问题，请联系：\(contact)。
    """
}

#if !os(macOS)
/// Renders a legal text: headings in the monitor's tracked caps, body in readable type.
struct LegalPageView: View {
    let title: String
    let text: String
    var body: some View {
        ScrollView {
            VStack(alignment: .leading, spacing: 14) {
                ForEach(LegalText.paragraphs(text)) { p in
                    if p.isHeading {
                        Text(p.text.uppercased()).font(Theme.label(12)).tracking(2).foregroundStyle(Theme.accent).padding(.top, p.id == 0 ? 0 : 10)
                    } else {
                        Text(p.text).font(.system(size: 15)).foregroundStyle(Theme.text).lineSpacing(3).fixedSize(horizontal: false, vertical: true)
                    }
                }
            }
            .padding(20)
            .frame(maxWidth: 700, alignment: .leading)
        }
        .background(Theme.field)
        .navigationTitle(title)
        .navigationBarTitleDisplayMode(.inline)
    }
}
#endif
