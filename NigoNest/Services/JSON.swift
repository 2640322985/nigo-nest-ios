import Foundation
import SwiftUI

enum JSON {
    static func object(_ data: Data) -> [String: Any] {
        (try? JSONSerialization.jsonObject(with: data) as? [String: Any]) ?? [:]
    }

    static func dictionaries(_ value: Any?) -> [[String: Any]] {
        value as? [[String: Any]] ?? []
    }

    static func string(_ value: Any?, fallback: String = "") -> String {
        if let text = value as? String { return text }
        if let number = value as? NSNumber { return number.stringValue }
        return fallback
    }

    static func int(_ value: Any?, fallback: Int = 0) -> Int {
        if let number = value as? Int { return number }
        if let number = value as? NSNumber { return number.intValue }
        if let text = value as? String, let number = Int(text) { return number }
        return fallback
    }

    static func double(_ value: Any?) -> Double? {
        if let number = value as? Double { return number }
        if let number = value as? NSNumber { return number.doubleValue }
        if let text = value as? String { return Double(text) }
        return nil
    }

    static func bool(_ value: Any?) -> Bool {
        if let flag = value as? Bool { return flag }
        if let number = value as? NSNumber { return number.boolValue }
        return false
    }
}

enum AppRoute: Hashable {
    case schedule
    case classroom
    case venue
    case orders
    case buddies
    case grab
    case yx
    case safety
    case friends
    case chat(String, String, String)
    case user(String)
    case notifications
    case suggestions
    case checkin
    case leaderboard
    case compose
    case mine
    case account
    case themes
    case post(Int)
}

@MainActor
final class AppNav: ObservableObject {
    @Published var path: [AppRoute] = []

    func open(_ route: AppRoute) {
        path.append(route)
    }
}
