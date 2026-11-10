import Foundation

struct VideoItem: Identifiable, Codable, Equatable {
    let id: String
    let title: String?
    let description: String?
    let poster: String?
    let duration: Double?
    let channel: String?
    let channel_id: String?
    let channel_avatar: String?
    let views: Int?
    let live: Bool?
    let viewers: Int?
    let url: String?
    let hls: String?
    let created: Double?

    var displayTitle: String {
        title?.isEmpty == false ? title! : "Без названия"
    }

    var displayChannel: String {
        channel?.isEmpty == false ? channel! : "Команда Чепушки"
    }

    var isLiveStream: Bool {
        live == true
    }

    var posterURL: URL? {
        guard let poster = poster, !poster.isEmpty else { return nil }
        if poster.hasPrefix("http") {
            return URL(string: poster)
        }
        return URL(string: "https://live.chepushkavpn.fun" + poster)
    }

    var streamURL: URL? {
        return URL(string: "https://live.chepushkavpn.fun/api/tv/manifest/\(id)/master.m3u8")
    }

    var formattedDuration: String {
        guard let sec = duration, sec > 0 else { return "00:00" }
        let total = Int(sec)
        let m = (total % 3600) / 60
        let s = total % 60
        let h = total / 3600
        if h > 0 {
            return String(format: "%d:%02d:%02d", h, m, s)
        }
        return String(format: "%02d:%02d", m, s)
    }

    var formattedViews: String {
        if isLiveStream {
            let v = viewers ?? 1
            return "\(v) зрителей"
        }
        let v = views ?? 0
        if v == 1 { return "1 просмотр" }
        if v >= 2 && v <= 4 { return "\(v) просмотра" }
        if v >= 1000 && v < 1_000_000 {
            return String(format: "%.1f тыс. просмотров", Double(v) / 1000.0)
        }
        return "\(v) просмотров"
    }

    var relativeTime: String {
        guard let cr = created, cr > 0 else { return "Недавно" }
        let diff = Date().timeIntervalSince1970 - cr
        if diff < 3600 { return "Только что" }
        let hours = Int(diff / 3600)
        if hours < 24 { return "\(hours) ч. назад" }
        let days = hours / 24
        if days < 7 { return "\(days) дн. назад" }
        let weeks = days / 7
        if weeks < 4 { return "\(weeks) нед. назад" }
        let months = days / 30
        return "\(months) мес. назад"
    }
}

struct CatalogResponse: Codable {
    let items: [VideoItem]
}

struct ChannelDetailResponse: Codable {
    let key: String?
    let id: String?
    let profile: ChannelProfileInfo?
    let subscribers: Int?
    let subscribed: Bool?
    let videos: [VideoItem]?
}

struct ChannelProfileInfo: Codable {
    let name: String?
    let about: String?
    let avatar: String?
    let verified: Bool?
    let role: String?
}

struct UserAccount: Codable, Equatable {
    let sub: String
    let role: String?
    let name: String?
    let username: String?
}

struct CategoryItem: Identifiable, Equatable {
    let id: String
    let label: String
    let icon: String
}
