import Foundation

struct SessionUser: Codable, Equatable {
    var studentId: String
    var name: String
    var nickname: String
    var token: String
    var avatarUrl: String?
}

@MainActor
final class SessionStore: ObservableObject {
    @Published private(set) var user: SessionUser?

    private let key = "nigo.nest.session"

    var isPreview: Bool {
        #if DEBUG
        return user?.token == "local-ui-preview"
        #else
        return false
        #endif
    }

    var displayDate: Date {
        if isPreview { return Date(timeIntervalSince1970: 1793662800) }
        return Date()
    }

    #if DEBUG
    init(preview: Bool) {
        if preview {
            user = SessionUser(studentId: "20260001", name: "小林同学", nickname: "小林同学", token: "local-ui-preview")
        }
    }
    #endif

    init() {
        guard let data = UserDefaults.standard.data(forKey: key),
              let saved = try? JSONDecoder().decode(SessionUser.self, from: data) else { return }
        guard saved.token != "local-ui-preview" else {
            UserDefaults.standard.removeObject(forKey: key)
            return
        }
        user = saved
    }

    var client: APIClient { APIClient(token: user?.token) }

    func login(username: String, password: String) async throws {
        let data = try await APIClient().post("api/auth/login", json: [
            "username": username,
            "password": password,
        ])
        let object = try JSONSerialization.jsonObject(with: data) as? [String: Any]
        let token = object?["authToken"] as? String ?? ""
        let profile = object?["user"] as? [String: Any] ?? [:]
        let studentId = (profile["studentId"] as? String) ?? username
        guard !token.isEmpty else { throw APIError.message("登录没有返回凭证") }
        let avatar = (profile["avatarUrl"] as? String) ?? ""
        let next = SessionUser(
            studentId: studentId,
            name: (profile["name"] as? String) ?? "",
            nickname: (profile["nickname"] as? String) ?? "同学",
            token: token,
            avatarUrl: avatar.hasPrefix("http") ? avatar : nil
        )
        user = next
        if let encoded = try? JSONEncoder().encode(next) {
            UserDefaults.standard.set(encoded, forKey: key)
        }
    }

    func apply(name: String? = nil, nickname: String? = nil, avatarUrl: String? = nil) {
        guard var next = user else { return }
        if let name { next.name = name }
        if let nickname { next.nickname = nickname }
        if let avatarUrl { next.avatarUrl = avatarUrl.hasPrefix("http") ? avatarUrl : nil }
        user = next
        guard !isPreview else { return }
        if let encoded = try? JSONEncoder().encode(next) {
            UserDefaults.standard.set(encoded, forKey: key)
        }
    }

    func logout() {
        let wasPreview = isPreview
        user = nil
        if !wasPreview { UserDefaults.standard.removeObject(forKey: key) }
    }
}
