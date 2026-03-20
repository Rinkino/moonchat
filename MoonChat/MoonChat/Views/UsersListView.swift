import SwiftUI

struct UsersListView: View {
    @EnvironmentObject var authVM: AuthViewModel
    @StateObject private var vm = UsersViewModel()

    var body: some View {
        NavigationStack {
            Group {
                if vm.isLoading {
                    ProgressView("Loading users…")
                } else if vm.users.isEmpty {
                    ContentUnavailableView("No Users", systemImage: "person.slash",
                                          description: Text("No other users registered yet."))
                } else {
                    List(vm.users, id: \.self) { user in
                        NavigationLink(destination: ChatView(recipient: user)) {
                            Label(user, systemImage: "person.circle")
                                .font(.body)
                        }
                    }
                }
            }
            .navigationTitle("Chats")
            .toolbar {
                ToolbarItem(placement: .topBarTrailing) {
                    Button("Sign Out") { authVM.logout() }
                        .foregroundStyle(.red)
                }
            }
            .task { await vm.loadUsers() }
            .refreshable { await vm.loadUsers() }
            .alert("Error", isPresented: Binding(
                get: { vm.errorMessage != nil },
                set: { if !$0 { vm.errorMessage = nil } }
            )) {
                Button("OK", role: .cancel) {}
            } message: {
                Text(vm.errorMessage ?? "")
            }
        }
    }
}
