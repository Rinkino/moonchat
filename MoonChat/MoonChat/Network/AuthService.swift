import Foundation

struct LoginRequest: Encodable {
    let username: String
    let password: String
}

struct SignupRequest: Encodable {
    let username: String
    let email: String
    let password: String
}

struct AuthResponse: Decodable {
    let token: String
}

class AuthService {
    static let shared = AuthService()
    private let client = APIClient.shared
    private init() {}

    func login(username: String, password: String) async throws -> String {
        let body = LoginRequest(username: username, password: password)
        let response: AuthResponse = try await client.post(path: "/auth/login", body: body, auth: false)
        return response.token
    }

    func signup(username: String, email: String, password: String) async throws -> String {
        let body = SignupRequest(username: username, email: email, password: password)
        let response: AuthResponse = try await client.post(path: "/auth/signup", body: body, auth: false)
        return response.token
    }
}
