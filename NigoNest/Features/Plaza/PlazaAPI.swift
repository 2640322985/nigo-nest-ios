import Foundation

struct PlazaPost: Identifiable, Equatable {
    let id: Int
    var nickname: String
    var avatarUrl: String?
    var content: String
    var likeCount: Int
    var commentCount: Int
}

enum PlazaAPI {
    static func load(page: Int, client: APIClient) async throws -> (posts: [PlazaPost], totalPages: Int) {
        let data = try await client.get("api/posts?page=\(page)&pageSize=10")
        let object = try JSONSerialization.jsonObject(with: data) as? [String: Any]
        let rows = object?["posts"] as? [[String: Any]] ?? []
        let posts = rows.compactMap { row -> PlazaPost? in
            guard let id = row["id"] as? Int ?? (row["id"] as? NSNumber)?.intValue else { return nil }
            let avatar = (row["avatarUrl"] as? String) ?? ""
            return PlazaPost(
                id: id,
                nickname: (row["nickname"] as? String) ?? "同学",
                avatarUrl: avatar.hasPrefix("http") ? avatar : nil,
                content: (row["content"] as? String) ?? "",
                likeCount: (row["likeCount"] as? Int) ?? (row["likeCount"] as? NSNumber)?.intValue ?? 0,
                commentCount: (row["commentCount"] as? Int) ?? (row["commentCount"] as? NSNumber)?.intValue ?? 0
            )
        }
        let totalPages = (object?["totalPages"] as? Int) ?? (object?["totalPages"] as? NSNumber)?.intValue ?? 1
        return (posts, max(totalPages, 1))
    }
}
