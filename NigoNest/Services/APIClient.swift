import Foundation

enum API {
    static func url(_ path: String) -> URL {
        let trimmed = path.trimmingCharacters(in: CharacterSet(charactersIn: "/"))
        return URL(string: "https://njtech.linfk.com/\(trimmed)")!
    }
}

enum APIError: LocalizedError {
    case message(String)
    case transport

    var errorDescription: String? {
        switch self {
        case .message(let text): return text
        case .transport: return "服务器连接失败"
        }
    }
}

struct APIClient {
    var token: String?

    func get(_ path: String) async throws -> Data {
        var request = URLRequest(url: API.url(path))
        request.httpMethod = "GET"
        return try await send(request)
    }

    func post(_ path: String, json: [String: Any]) async throws -> Data {
        var request = URLRequest(url: API.url(path))
        request.httpMethod = "POST"
        request.setValue("application/json", forHTTPHeaderField: "Content-Type")
        request.httpBody = try JSONSerialization.data(withJSONObject: json)
        return try await send(request)
    }

    private func send(_ request: URLRequest) async throws -> Data {
        var request = request
        if let token, !token.isEmpty {
            request.setValue(token, forHTTPHeaderField: "x-auth-token")
        }
        request.timeoutInterval = 40
        let data: Data
        let response: URLResponse
        do {
            (data, response) = try await URLSession.shared.data(for: request)
        } catch {
            throw APIError.transport
        }
        guard let http = response as? HTTPURLResponse else { throw APIError.transport }
        if (200 ..< 300).contains(http.statusCode) { return data }
        if let object = try? JSONSerialization.jsonObject(with: data) as? [String: Any],
           let message = object["message"] as? String, !message.isEmpty {
            throw APIError.message(message)
        }
        throw APIError.message("请求失败 (\(http.statusCode))")
    }
}
