import Foundation

@MainActor
class UsersViewModel: ObservableObject {
    @Published var users: [String] = []
    @Published var isLoading = false
    @Published var errorMessage: String?

    func loadUsers() async {
        isLoading = true
        errorMessage = nil
        defer { isLoading = false }
        do {
            users = try await ChatService.shared.getUsers()
        } catch {
            errorMessage = error.localizedDescription
        }
    }
}
