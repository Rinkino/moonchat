import Foundation

enum APIError: Error, LocalizedError {
    case invalidURL
    case httpError(Int)
    case decodingError(Error)
    case networkError(Error)
    case unauthorized

    var errorDescription: String? {
        switch self {
        case .invalidURL: return "Invalid URL"
        case .httpError(let code): return "HTTP error \(code)"
        case .decodingError(let e): return "Decode error: \(e.localizedDescription)"
        case .networkError(let e): return e.localizedDescription
        case .unauthorized: return "Unauthorized — please log in again"
        }
    }
}

// MARK: - Token Store

enum TokenStore {
    private static let tokenKey = "jwt_token"
    private static let usernameKey = "username"

    static var token: String? {
        get { UserDefaults.standard.string(forKey: tokenKey) }
        set { UserDefaults.standard.set(newValue, forKey: tokenKey) }
    }

    static var username: String? {
        get { UserDefaults.standard.string(forKey: usernameKey) }
        set { UserDefaults.standard.set(newValue, forKey: usernameKey) }
    }

    static func clear() {
        UserDefaults.standard.removeObject(forKey: tokenKey)
        UserDefaults.standard.removeObject(forKey: usernameKey)
    }
}

// MARK: - API Client

class APIClient {
    static let shared = APIClient()

    let baseURL = "http://localhost:8080"

    private init() {}

    private func makeRequest(
        path: String,
        method: String,
        body: Data? = nil,
        requiresAuth: Bool = true
    ) throws -> URLRequest {
        guard let url = URL(string: baseURL + path) else {
            throw APIError.invalidURL
        }
        var request = URLRequest(url: url)
        request.httpMethod = method
        request.setValue("application/json", forHTTPHeaderField: "Content-Type")
        if requiresAuth, let token = TokenStore.token {
            request.setValue("Bearer \(token)", forHTTPHeaderField: "Authorization")
        }
        request.httpBody = body
        return request
    }

    func post<T: Decodable>(path: String, body: Encodable, auth: Bool = false) async throws -> T {
        let data = try JSONEncoder().encode(body)
        let request = try makeRequest(path: path, method: "POST", body: data, requiresAuth: auth)
        return try await execute(request)
    }

    func get<T: Decodable>(path: String) async throws -> T {
        let request = try makeRequest(path: path, method: "GET")
        return try await execute(request)
    }

    private func execute<T: Decodable>(_ request: URLRequest) async throws -> T {
        let (data, response) = try await URLSession.shared.data(for: request)
        guard let http = response as? HTTPURLResponse else {
            throw APIError.networkError(URLError(.badServerResponse))
        }
        if http.statusCode == 401 { throw APIError.unauthorized }
        guard (200..<300).contains(http.statusCode) else {
            throw APIError.httpError(http.statusCode)
        }
        do {
            return try JSONDecoder().decode(T.self, from: data)
        } catch {
            throw APIError.decodingError(error)
        }
    }

    // For endpoints that return no body (200 OK, void)
    func postVoid(path: String, body: Encodable) async throws {
        let data = try JSONEncoder().encode(body)
        var request = try makeRequest(path: path, method: "POST", body: data)
        let (_, response) = try await URLSession.shared.data(for: request)
        guard let http = response as? HTTPURLResponse else { return }
        if http.statusCode == 401 { throw APIError.unauthorized }
        guard (200..<300).contains(http.statusCode) else {
            throw APIError.httpError(http.statusCode)
        }
    }
}
