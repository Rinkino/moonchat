import Foundation

@MainActor
class ChatViewModel: ObservableObject {
    @Published var messages: [Message] = []
    @Published var isLoading = false
    @Published var errorMessage: String?

    let recipient: String

    init(recipient: String) {
        self.recipient = recipient
    }

    func loadHistory() async {
        isLoading = true
        defer { isLoading = false }
        do {
            messages = try await ChatService.shared.getHistory(with: recipient)
            connectWebSocket()
        } catch {
            errorMessage = error.localizedDescription
        }
    }

    func sendMessage(_ content: String) async {
        guard !content.trimmingCharacters(in: .whitespaces).isEmpty else { return }

        // Optimistic insert
        let temp = Message(
            id: Int.random(in: Int.min..<0),
            message: content,
            sender: TokenStore.username ?? "",
            receiver: recipient,
            sentAt: ISO8601DateFormatter().string(from: Date())
        )
        messages.append(temp)

        do {
            try await ChatService.shared.sendMessage(content: content, to: recipient)
        } catch {
            // Remove optimistic message on failure
            messages.removeAll { $0.id == temp.id }
            errorMessage = error.localizedDescription
        }
    }

    // MARK: - WebSocket

    func connectWebSocket() {
        guard let token = TokenStore.token else { return }
        StompWebSocketService.shared.connect(token: token) { [weak self] msg in
            guard let self else { return }
            // Only accept messages relevant to this conversation
            if msg.sender == self.recipient || msg.receiver == self.recipient {
                // Avoid duplicate if already present (REST send echoed back)
                if !self.messages.contains(where: { $0.id == msg.id }) {
                    self.messages.append(msg)
                }
            }
        }
    }

    func disconnectWebSocket() {
        StompWebSocketService.shared.disconnect()
    }
}
