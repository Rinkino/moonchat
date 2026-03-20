import SwiftUI

struct ChatView: View {
    let recipient: String
    @StateObject private var vm: ChatViewModel
    @State private var inputText = ""
    @FocusState private var inputFocused: Bool

    init(recipient: String) {
        self.recipient = recipient
        _vm = StateObject(wrappedValue: ChatViewModel(recipient: recipient))
    }

    var body: some View {
        VStack(spacing: 0) {
            messagesScrollView
            Divider()
            inputBar
        }
        .navigationTitle(recipient)
        .navigationBarTitleDisplayMode(.inline)
        .task { await vm.loadHistory() }
        .onDisappear { vm.disconnectWebSocket() }
        .alert("Error", isPresented: Binding(
            get: { vm.errorMessage != nil },
            set: { if !$0 { vm.errorMessage = nil } }
        )) {
            Button("OK", role: .cancel) {}
        } message: {
            Text(vm.errorMessage ?? "")
        }
    }

    // MARK: - Subviews

    private var messagesScrollView: some View {
        ScrollViewReader { proxy in
            ScrollView {
                LazyVStack(spacing: 8) {
                    if vm.isLoading {
                        ProgressView().padding()
                    }
                    ForEach(vm.messages) { msg in
                        MessageBubble(message: msg)
                            .id(msg.id)
                    }
                }
                .padding(.vertical, 8)
            }
            .onChange(of: vm.messages.count) { _, _ in
                if let last = vm.messages.last {
                    withAnimation { proxy.scrollTo(last.id, anchor: .bottom) }
                }
            }
        }
    }

    private var inputBar: some View {
        HStack(spacing: 12) {
            TextField("Message…", text: $inputText, axis: .vertical)
                .lineLimit(1...5)
                .textFieldStyle(.roundedBorder)
                .focused($inputFocused)
                .onSubmit { sendMessage() }

            Button(action: sendMessage) {
                Image(systemName: "arrow.up.circle.fill")
                    .font(.system(size: 32))
                    .foregroundStyle(inputText.isEmpty ? .gray : .indigo)
            }
            .disabled(inputText.trimmingCharacters(in: .whitespaces).isEmpty)
        }
        .padding(.horizontal)
        .padding(.vertical, 8)
        .background(.bar)
    }

    private func sendMessage() {
        let text = inputText.trimmingCharacters(in: .whitespaces)
        guard !text.isEmpty else { return }
        inputText = ""
        Task { await vm.sendMessage(text) }
    }
}

// MARK: - Message Bubble

struct MessageBubble: View {
    let message: Message

    var body: some View {
        HStack {
            if message.isSentByMe { Spacer(minLength: 60) }

            Text(message.message)
                .padding(.horizontal, 14)
                .padding(.vertical, 10)
                .background(message.isSentByMe ? Color.indigo : Color(.systemGray5))
                .foregroundStyle(message.isSentByMe ? .white : .primary)
                .clipShape(RoundedRectangle(cornerRadius: 18))

            if !message.isSentByMe { Spacer(minLength: 60) }
        }
        .padding(.horizontal, 12)
    }
}
