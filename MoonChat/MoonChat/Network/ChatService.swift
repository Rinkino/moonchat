import Foundation

struct SendMessageRequest: Encodable {
    let content: String
    let recipientUsername: String
}

class ChatService {
    static let shared = ChatService()
    private let client = APIClient.shared
    private init() {}

    func getUsers() async throws -> [String] {
        return try await client.get(path: "/chat/users")
    }

    func getHistory(with username: String) async throws -> [Message] {
        return try await client.get(path: "/chat/history/\(username)")
    }

    func sendMessage(content: String, to recipient: String) async throws {
        let body = SendMessageRequest(content: content, recipientUsername: recipient)
        try await client.postVoid(path: "/chat/send", body: body)
    }
}
