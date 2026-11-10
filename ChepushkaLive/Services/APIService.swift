import Foundation
import Combine

class APIService: ObservableObject {
    static let shared = APIService()
    static let baseURL = "https://live.chepushkavpn.fun"

    @Published var account: UserAccount?
    @Published var favorites: Set<String> = []
    @Published var localSubscriptions: Set<String> = []

    private let accountKey = "cp_ios_account"
    private let favoritesKey = "cp_ios_favorites"
    private let subscriptionsKey = "cp_ios_subscriptions"

    init() {
        loadFromStorage()
    }

    func loadFromStorage() {
        if let data = UserDefaults.standard.data(forKey: accountKey),
           let acc = try? JSONDecoder().decode(UserAccount.self, from: data) {
            self.account = acc
        }
        if let favs = UserDefaults.standard.array(forKey: favoritesKey) as? [String] {
            self.favorites = Set(favs)
        }
        if let subs = UserDefaults.standard.array(forKey: subscriptionsKey) as? [String] {
            self.localSubscriptions = Set(subs)
        }
    }

    func saveAccount(_ acc: UserAccount?) {
        self.account = acc
        if let acc = acc, let data = try? JSONEncoder().encode(acc) {
            UserDefaults.standard.set(data, forKey: accountKey)
        } else {
            UserDefaults.standard.removeObject(forKey: accountKey)
        }
    }

    func toggleFavorite(_ videoId: String) {
        if favorites.contains(videoId) {
            favorites.remove(videoId)
        } else {
            favorites.insert(videoId)
        }
        UserDefaults.standard.set(Array(favorites), forKey: favoritesKey)
    }

    var viewerSubId: String {
        if let acc = account {
            return "\(acc.role ?? "viewer"):\(acc.sub)"
        }
        return "ios_guest"
    }

    // MARK: - Catalog
    func fetchCatalog() async throws -> [VideoItem] {
        guard let url = URL(string: "\(Self.baseURL)/api/tv/catalog") else {
            throw URLError(.badURL)
        }
        let (data, response) = try await URLSession.shared.data(from: url)
        guard let http = response as? HTTPURLResponse, http.statusCode == 200 else {
            throw URLError(.badServerResponse)
        }
        let res = try JSONDecoder().decode(CatalogResponse.self, from: data)
        return res.items
    }

    // MARK: - Channel Detail
    func fetchChannel(key: String) async throws -> ChannelDetailResponse {
        let sub = viewerSubId
        let encodedKey = key.addingPercentEncoding(withAllowedCharacters: .urlPathAllowed) ?? key
        let encodedSub = sub.addingPercentEncoding(withAllowedCharacters: .urlQueryAllowed) ?? sub
        guard let url = URL(string: "\(Self.baseURL)/api/tv/channels/\(encodedKey)?sub=\(encodedSub)") else {
            throw URLError(.badURL)
        }
        let (data, _) = try await URLSession.shared.data(from: url)
        return try JSONDecoder().decode(ChannelDetailResponse.self, from: data)
    }

    // MARK: - Subscribe
    func toggleSubscribe(channelKey: String) async throws -> (subscribed: Bool, subscribers: Int) {
        guard let account = account else {
            throw NSError(domain: "AuthRequired", code: 401, userInfo: [NSLocalizedDescriptionKey: "Для подписки необходимо войти в аккаунт"])
        }
        let sub = "\(account.role ?? "viewer"):\(account.sub)"
        let encodedKey = channelKey.addingPercentEncoding(withAllowedCharacters: .urlPathAllowed) ?? channelKey
        guard let url = URL(string: "\(Self.baseURL)/api/tv/channels/\(encodedKey)/subscribe") else {
            throw URLError(.badURL)
        }
        var req = URLRequest(url: url)
        req.httpMethod = "POST"
        req.setValue("application/json", forHTTPHeaderField: "Content-Type")
        req.httpBody = try JSONSerialization.data(withJSONObject: ["sub": sub])

        let (data, response) = try await URLSession.shared.data(for: req)
        guard let http = response as? HTTPURLResponse, http.statusCode == 200 else {
            throw URLError(.badServerResponse)
        }
        struct SubResponse: Codable {
            let subscribed: Bool
            let subscribers: Int
        }
        let res = try JSONDecoder().decode(SubResponse.self, from: data)
        if res.subscribed {
            localSubscriptions.insert(channelKey)
        } else {
            localSubscriptions.remove(channelKey)
        }
        UserDefaults.standard.set(Array(localSubscriptions), forKey: subscriptionsKey)
        return (res.subscribed, res.subscribers)
    }

    // MARK: - Auth (QR & Code)
    struct AuthStartResponse: Codable {
        let session_id: String
        let code: String
        let qr_url: String?
        let poll_token: String
        let expires_in: Int
    }

    struct AuthPollResponse: Codable {
        let status: String
        let account: UserAccount?
    }

    func startAuth() async throws -> AuthStartResponse {
        guard let url = URL(string: "\(Self.baseURL)/api/tv/auth/start") else {
            throw URLError(.badURL)
        }
        var req = URLRequest(url: url)
        req.httpMethod = "POST"
        req.setValue("application/json", forHTTPHeaderField: "Content-Type")
        req.httpBody = "{}".data(using: .utf8)
        let (data, _) = try await URLSession.shared.data(for: req)
        return try JSONDecoder().decode(AuthStartResponse.self, from: data)
    }

    func pollAuth(sessionId: String, pollToken: String) async throws -> AuthPollResponse {
        guard let url = URL(string: "\(Self.baseURL)/api/tv/auth/poll") else {
            throw URLError(.badURL)
        }
        var req = URLRequest(url: url)
        req.httpMethod = "POST"
        req.setValue("application/json", forHTTPHeaderField: "Content-Type")
        let body: [String: Any] = [
            "session_id": sessionId,
            "poll_token": pollToken
        ]
        req.httpBody = try JSONSerialization.data(withJSONObject: body)
        let (data, _) = try await URLSession.shared.data(for: req)
        return try JSONDecoder().decode(AuthPollResponse.self, from: data)
    }
}
