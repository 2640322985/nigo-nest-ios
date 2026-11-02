import Foundation

struct SessionUser: Codable, Equatable {
    var studentId: String
    var name: String
    var nickname: String
    var token: String
}

@MainActor
final class SessionStore: ObservableObject {
    @Published private(set) var user: SessionUser?

    private let key = "nigo.nest.session"

    init() {
        guard let data = UserDefaults.standard.data(forKey: key),
              let saved = try? JSONDecoder().decode(SessionUser.self, from: data) else { return }
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
        let next = SessionUser(
            studentId: studentId,
            name: (profile["name"] as? String) ?? "",
            nickname: (profile["nickname"] as? String) ?? "同学",
            token: token
        )
        user = next
        if let encoded = try? JSONEncoder().encode(next) {
            UserDefaults.standard.set(encoded, forKey: key)
        }
    }

    func logout() {
        user = nil
        UserDefaults.standard.removeObject(forKey: key)
    }
}
