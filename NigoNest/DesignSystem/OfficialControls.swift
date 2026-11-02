import SwiftUI

extension View {
    /// 官方按钮。iOS 26 起是玻璃样式，iOS 18–25 用系统描边按钮。
    @ViewBuilder
    func officialAction(prominent: Bool = true) -> some View {
        if #available(iOS 26, *) {
            if prominent {
                self.buttonStyle(.glassProminent).controlSize(.large)
            } else {
                self.buttonStyle(.glass).controlSize(.large)
            }
        } else if prominent {
            self.buttonStyle(.borderedProminent).controlSize(.large)
        } else {
            self.buttonStyle(.bordered).controlSize(.large)
        }
    }
}
