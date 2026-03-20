import Foundation

struct Message: Codable, Identifiable {
    let id: Int
    let message: String
    let sender: String
    let receiver: String
    let sentAt: String

    var isSentByMe: Bool {
        sender == TokenStore.username
    }
}
