import Foundation

@MainActor
class AuthViewModel: ObservableObject {
    @Published var isLoggedIn: Bool = TokenStore.token != nil
    @Published var isLoading = false
    @Published var errorMessage: String?

    func login(username: String, password: String) async {
        isLoading = true
        errorMessage = nil
        defer { isLoading = false }
        do {
            let token = try await AuthService.shared.login(username: username, password: password)
            TokenStore.token = token
            TokenStore.username = username
            isLoggedIn = true
        } catch {
            errorMessage = error.localizedDescription
        }
    }

    func signup(username: String, email: String, password: String) async {
        isLoading = true
        errorMessage = nil
        defer { isLoading = false }
        do {
            let token = try await AuthService.shared.signup(username: username, email: email, password: password)
            TokenStore.token = token
            TokenStore.username = username
            isLoggedIn = true
        } catch {
            errorMessage = error.localizedDescription
        }
    }

    func logout() {
        StompWebSocketService.shared.disconnect()
        TokenStore.clear()
        isLoggedIn = false
    }
}
