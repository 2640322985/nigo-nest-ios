import Foundation

enum AppTheme: String, CaseIterable, Identifiable {
    case monochrome
    case journal
    var id: String { rawValue }
    var title: String { self == .monochrome ? "黑白校园" : "课间手账" }
    var subtitle: String {
        self == .monochrome ? "黑白留白，安静清晰" : "奶油纸张，红蓝笔色与校园猫咪"
    }
    static func resolve(_ raw: String?) -> AppTheme {
        raw.flatMap(AppTheme.init(rawValue:)) ?? .monochrome
    }
}

enum ThemePreference {
    static let key = "nigo.appearance.theme"
    static func load(from defaults: UserDefaults = .standard) -> AppTheme {
        AppTheme.resolve(defaults.string(forKey: key))
    }
    static func save(_ theme: AppTheme, to defaults: UserDefaults = .standard) {
        defaults.set(theme.rawValue, forKey: key)
    }
}
