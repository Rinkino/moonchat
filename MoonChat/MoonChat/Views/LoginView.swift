import SwiftUI

struct LoginView: View {
    @EnvironmentObject var authVM: AuthViewModel
    @State private var username = ""
    @State private var password = ""
    @State private var showSignup = false

    var body: some View {
        NavigationStack {
            VStack(spacing: 24) {
                Spacer()

                Image(systemName: "moon.fill")
                    .font(.system(size: 64))
                    .foregroundStyle(.indigo)

                Text("MoonChat")
                    .font(.largeTitle.bold())

                VStack(spacing: 12) {
                    TextField("Username", text: $username)
                        .textInputAutocapitalization(.never)
                        .autocorrectionDisabled()
                        .textFieldStyle(.roundedBorder)

                    SecureField("Password", text: $password)
                        .textFieldStyle(.roundedBorder)
                }
                .padding(.horizontal)

                if let error = authVM.errorMessage {
                    Text(error)
                        .foregroundStyle(.red)
                        .font(.footnote)
                        .multilineTextAlignment(.center)
                        .padding(.horizontal)
                }

                Button {
                    Task { await authVM.login(username: username, password: password) }
                } label: {
                    Group {
                        if authVM.isLoading {
                            ProgressView()
                        } else {
                            Text("Sign In")
                                .fontWeight(.semibold)
                        }
                    }
                    .frame(maxWidth: .infinity)
                    .padding()
                    .background(.indigo)
                    .foregroundStyle(.white)
                    .clipShape(RoundedRectangle(cornerRadius: 12))
                }
                .disabled(authVM.isLoading || username.isEmpty || password.isEmpty)
                .padding(.horizontal)

                Button("Don't have an account? Sign up") {
                    showSignup = true
                }
                .font(.footnote)

                Spacer()
            }
            .navigationDestination(isPresented: $showSignup) {
                SignupView()
                    .environmentObject(authVM)
            }
        }
    }
}
