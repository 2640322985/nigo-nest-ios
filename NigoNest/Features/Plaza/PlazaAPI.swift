import Foundation

struct PlazaPost: Identifiable, Equatable {
    let id: Int
    var studentId: String
    var nickname: String
    var avatarUrl: String?
    var content: String
    var likeCount: Int
    var commentCount: Int
    var likedByMe: Bool
}

struct PlazaComment: Identifiable, Equatable {
    let id: Int
    var studentId: String
    var nickname: String
    var avatarUrl: String?
    var content: String
    var replyName: String
}

enum PlazaAPI {
    static func load(page: Int, client: APIClient) async throws -> (posts: [PlazaPost], totalPages: Int) {
        let data = JSON.object(try await client.get("api/posts?page=\(page)&pageSize=10"))
        let posts = JSON.dictionaries(data["posts"]).compactMap(post)
        let totalPages = JSON.int(data["totalPages"], fallback: 1)
        return (posts, max(totalPages, 1))
    }

    static func comments(postId: Int, client: APIClient) async throws -> [PlazaComment] {
        let data = JSON.object(try await client.get("api/posts/\(postId)/comments"))
        return JSON.dictionaries(data["comments"]).compactMap { row in
            let id = JSON.int(row["id"])
            guard id > 0 else { return nil }
            let reply = row["replyTo"] as? [String: Any]
            let avatar = JSON.string(row["avatarUrl"])
            return PlazaComment(
                id: id,
                studentId: JSON.string(row["studentId"]),
                nickname: JSON.string(row["nickname"], fallback: "同学"),
                avatarUrl: avatar.hasPrefix("http") ? avatar : nil,
                content: JSON.string(row["content"]),
                replyName: JSON.string(reply?["nickname"])
            )
        }
    }

    private static func post(_ row: [String: Any]) -> PlazaPost? {
        let id = JSON.int(row["id"])
        guard id > 0 else { return nil }
        let avatar = JSON.string(row["avatarUrl"])
        return PlazaPost(
            id: id,
            studentId: JSON.string(row["studentId"]),
            nickname: JSON.string(row["nickname"], fallback: "同学"),
            avatarUrl: avatar.hasPrefix("http") ? avatar : nil,
            content: JSON.string(row["content"]),
            likeCount: JSON.int(row["likeCount"]),
            commentCount: JSON.int(row["commentCount"]),
            likedByMe: JSON.bool(row["likedByMe"])
        )
    }
}
