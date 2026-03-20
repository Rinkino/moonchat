import Foundation

// Minimal STOMP 1.1 client over URLSessionWebSocketTask
// Connects to /ws, authenticates via Authorization header in STOMP CONNECT frame,
// subscribes to /user/queue/messages, and publishes to /app/chat.

typealias MessageHandler = (Message) -> Void

class StompWebSocketService: NSObject {

    static let shared = StompWebSocketService()

    private var webSocketTask: URLSessionWebSocketTask?
    private var urlSession: URLSession?
    private var messageHandler: MessageHandler?
    private var isConnected = false

    private override init() {
        super.init()
    }

    // MARK: - Connect

    func connect(token: String, onMessage: @escaping MessageHandler) {
        self.messageHandler = onMessage
        disconnect()

        guard let url = URL(string: "\(APIClient.shared.baseURL)/ws/websocket") else { return }

        urlSession = URLSession(configuration: .default, delegate: self, delegateQueue: nil)
        webSocketTask = urlSession?.webSocketTask(with: url)
        webSocketTask?.resume()

        sendStompConnect(token: token)
        listenForMessages()
    }

    // MARK: - Disconnect

    func disconnect() {
        webSocketTask?.cancel(with: .normalClosure, reason: nil)
        webSocketTask = nil
        urlSession = nil
        isConnected = false
    }

    // MARK: - Send Chat Message via STOMP

    func sendChatMessage(content: String, to recipient: String) {
        guard isConnected else { return }
        let body = #"{"content":"\#(content)","recipientUsername":"\#(recipient)"}"#
        let frame = stompFrame(
            command: "SEND",
            headers: [
                "destination": "/app/chat",
                "content-type": "application/json",
                "content-length": "\(body.utf8.count)"
            ],
            body: body
        )
        send(frame)
    }

    // MARK: - Private STOMP helpers

    private func sendStompConnect(token: String) {
        let frame = stompFrame(
            command: "CONNECT",
            headers: [
                "accept-version": "1.1,1.2",
                "heart-beat": "0,0",
                "Authorization": "Bearer \(token)"
            ]
        )
        send(frame)
    }

    private func sendStompSubscribe() {
        let frame = stompFrame(
            command: "SUBSCRIBE",
            headers: [
                "id": "sub-0",
                "destination": "/user/queue/messages"
            ]
        )
        send(frame)
    }

    private func stompFrame(command: String, headers: [String: String], body: String = "") -> String {
        var frame = command + "\n"
        for (key, value) in headers {
            frame += "\(key):\(value)\n"
        }
        frame += "\n"
        frame += body
        frame += "\0"
        return frame
    }

    private func send(_ frame: String) {
        webSocketTask?.send(.string(frame)) { error in
            if let error { print("[STOMP] Send error:", error) }
        }
    }

    // MARK: - Receive loop

    private func listenForMessages() {
        webSocketTask?.receive { [weak self] result in
            guard let self else { return }
            switch result {
            case .success(let message):
                switch message {
                case .string(let text):
                    self.handleFrame(text)
                case .data:
                    break
                @unknown default:
                    break
                }
                self.listenForMessages()
            case .failure(let error):
                print("[STOMP] Receive error:", error)
                self.isConnected = false
            }
        }
    }

    // MARK: - Frame parser

    private func handleFrame(_ text: String) {
        guard !text.trimmingCharacters(in: .whitespacesAndNewlines).isEmpty else { return }

        let parts = text.components(separatedBy: "\n\n")
        guard parts.count >= 1 else { return }

        let headerSection = parts[0]
        let body = parts.count >= 2 ? parts[1].replacingOccurrences(of: "\0", with: "") : ""
        let lines = headerSection.components(separatedBy: "\n")
        let command = lines.first ?? ""

        switch command {
        case "CONNECTED":
            isConnected = true
            sendStompSubscribe()

        case "MESSAGE":
            guard !body.isEmpty,
                  let data = body.data(using: .utf8) else { return }
            do {
                let msg = try JSONDecoder().decode(Message.self, from: data)
                DispatchQueue.main.async { self.messageHandler?(msg) }
            } catch {
                print("[STOMP] Failed to decode message:", error)
            }

        case "ERROR":
            print("[STOMP] ERROR frame:", text)

        default:
            break
        }
    }
}

// MARK: - URLSessionWebSocketDelegate

extension StompWebSocketService: URLSessionWebSocketDelegate {
    func urlSession(_ session: URLSession,
                    webSocketTask: URLSessionWebSocketTask,
                    didOpenWithProtocol protocol: String?) {
        print("[STOMP] WebSocket opened")
    }

    func urlSession(_ session: URLSession,
                    webSocketTask: URLSessionWebSocketTask,
                    didCloseWith closeCode: URLSessionWebSocketTask.CloseCode,
                    reason: Data?) {
        isConnected = false
        print("[STOMP] WebSocket closed:", closeCode)
    }
}
