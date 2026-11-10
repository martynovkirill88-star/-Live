import SwiftUI

struct ChannelProfileView: View {
    let channelKey: String
    let channelName: String
    @Environment(\.dismiss) private var dismiss
    @ObservedObject var api = APIService.shared

    @State private var channelDetail: ChannelDetailResponse?
    @State private var isSubscribed = false
    @State private var subscribersCount = 0
    @State private var videos: [VideoItem] = []
    @State private var activeTab = 0
    @State private var showAuthSheet = false
    @State private var selectedVideo: VideoItem?

    var body: some View {
        NavigationView {
            ScrollView {
                VStack(spacing: 0) {
                    // Channel Header / Banner Card
                    VStack(spacing: 16) {
                        // Large Avatar Circle
                        ZStack {
                            Circle()
                                .fill(AppTheme.accent)
                                .frame(width: 96, height: 96)

                            if let avatarStr = channelDetail?.profile?.avatar,
                               let url = URL(string: avatarStr.hasPrefix("http") ? avatarStr : "https://live.chepushkavpn.fun" + avatarStr) {
                                AsyncImage(url: url) { phase in
                                    if let img = phase.image {
                                        img.resizable().aspectRatio(contentMode: .fill)
                                    } else {
                                        Text(String(channelName.prefix(1)).uppercased())
                                            .font(.system(size: 38, weight: .bold))
                                            .foregroundColor(AppTheme.accentDark)
                                    }
                                }
                                .frame(width: 96, height: 96)
                                .clipShape(Circle())
                            } else {
                                Text(String(channelName.prefix(1)).uppercased())
                                    .font(.system(size: 38, weight: .bold))
                                    .foregroundColor(AppTheme.accentDark)
                            }
                        }
                        .overlay(
                            Circle()
                                .stroke(AppTheme.surfaceAlt, lineWidth: 4)
                        )
                        .padding(.top, 16)

                        // Channel Title & Verified Badge
                        VStack(spacing: 6) {
                            HStack(spacing: 6) {
                                Text(channelDetail?.profile?.name ?? channelName)
                                    .font(.system(size: 22, weight: .bold))
                                    .foregroundColor(AppTheme.textPrimary)
                                Image(systemName: "checkmark.seal.fill")
                                    .font(.system(size: 16))
                                    .foregroundColor(AppTheme.accent)
                            }

                            // Stats: handle, subscribers, videos count
                            HStack(spacing: 6) {
                                Text(subscribersText)
                                Text("·")
                                Text("\(videos.count) видео")
                            }
                            .font(.system(size: 13))
                            .foregroundColor(AppTheme.textSecondary)

                            // Bio description
                            if let about = channelDetail?.profile?.about, !about.isEmpty {
                                Text(about)
                                    .font(.system(size: 14))
                                    .foregroundColor(AppTheme.textSecondary)
                                    .multilineTextAlignment(.center)
                                    .lineLimit(3)
                                    .padding(.horizontal, 24)
                                    .padding(.top, 4)
                            }
                        }

                        // Subscribe Button (Full Width matching mockups)
                        Button(action: handleSubscribeToggle) {
                            HStack(spacing: 8) {
                                if isSubscribed {
                                    Image(systemName: "checkmark")
                                        .font(.system(size: 14, weight: .bold))
                                    Text("Вы подписаны")
                                        .font(.system(size: 16, weight: .bold))
                                } else {
                                    Text("Подписаться")
                                        .font(.system(size: 16, weight: .bold))
                                }
                            }
                            .frame(maxWidth: .infinity)
                            .frame(height: 48)
                            .foregroundColor(isSubscribed ? AppTheme.textPrimary : AppTheme.accentDark)
                            .background(isSubscribed ? AppTheme.surface : AppTheme.accent)
                            .cornerRadius(24)
                            .overlay(
                                RoundedRectangle(cornerRadius: 24)
                                    .stroke(isSubscribed ? AppTheme.accent : Color.clear, lineWidth: 1.5)
                            )
                        }
                        .padding(.horizontal, 24)
                    }
                    .padding(.bottom, 24)
                    .background(
                        RadialGradient(
                            colors: [AppTheme.backgroundRadial.opacity(0.8), AppTheme.background],
                            center: .top,
                            startRadius: 20,
                            endRadius: 300
                        )
                    )

                    // Tabs row: «Видео», «Плейлисты»
                    HStack(spacing: 12) {
                        Button(action: { activeTab = 0 }) {
                            Text("Видео")
                                .font(.system(size: 14, weight: .bold))
                                .padding(.horizontal, 16)
                                .padding(.vertical, 8)
                                .foregroundColor(activeTab == 0 ? AppTheme.accentDark : AppTheme.textPrimary)
                                .background(activeTab == 0 ? AppTheme.accent : AppTheme.surface)
                                .cornerRadius(16)
                        }

                        Button(action: { activeTab = 1 }) {
                            Text("Плейлисты")
                                .font(.system(size: 14, weight: .bold))
                                .padding(.horizontal, 16)
                                .padding(.vertical, 8)
                                .foregroundColor(activeTab == 1 ? AppTheme.accentDark : AppTheme.textPrimary)
                                .background(activeTab == 1 ? AppTheme.accent : AppTheme.surface)
                                .cornerRadius(16)
                        }

                        Spacer()
                    }
                    .padding(.horizontal, 16)
                    .padding(.vertical, 12)

                    // Videos Feed
                    if videos.isEmpty {
                        VStack(spacing: 12) {
                            Image(systemName: "video.slash")
                                .font(.system(size: 40))
                                .foregroundColor(AppTheme.textSecondary)
                            Text("У канала пока нет опубликованных видео")
                                .font(.system(size: 15))
                                .foregroundColor(AppTheme.textSecondary)
                        }
                        .padding(.vertical, 60)
                    } else {
                        LazyVStack(spacing: 8) {
                            ForEach(videos) { item in
                                Button(action: { selectedVideo = item }) {
                                    VideoCardView(item: item, onChannelTap: {})
                                }
                                .buttonStyle(PlainButtonStyle())
                            }
                        }
                    }
                }
            }
            .background(AppTheme.background.ignoresSafeArea())
            .navigationBarTitleDisplayMode(.inline)
            .toolbar {
                ToolbarItem(placement: .navigationBarLeading) {
                    Button(action: { dismiss() }) {
                        Image(systemName: "chevron.left")
                            .font(.system(size: 16, weight: .bold))
                            .foregroundColor(AppTheme.textPrimary)
                    }
                }
                ToolbarItem(placement: .principal) {
                    Text(channelDetail?.profile?.name ?? channelName)
                        .font(.system(size: 16, weight: .bold))
                        .foregroundColor(AppTheme.textPrimary)
                }
                ToolbarItem(placement: .navigationBarTrailing) {
                    Button(action: {}) {
                        Image(systemName: "square.and.arrow.up")
                            .font(.system(size: 16))
                            .foregroundColor(AppTheme.textPrimary)
                    }
                }
            }
            .onAppear(perform: loadChannel)
            .fullScreenCover(item: $selectedVideo) { v in
                WatchVideoView(video: v)
            }
            .sheet(isPresented: $showAuthSheet) {
                AuthView()
            }
        }
    }

    private var subscribersText: String {
        let s = subscribersCount
        if s == 1 { return "1 подписчик" }
        if s >= 2 && s <= 4 { return "\(s) подписчика" }
        if s >= 1000 && s < 1_000_000 {
            return String(format: "%.1f тыс. подписчиков", Double(s)/1000.0)
        }
        return "\(s) подписчиков"
    }

    private func loadChannel() {
        Task {
            do {
                let res = try await api.fetchChannel(key: channelKey)
                await MainActor.run {
                    self.channelDetail = res
                    self.isSubscribed = res.subscribed == true || api.localSubscriptions.contains(channelKey)
                    self.subscribersCount = res.subscribers ?? 0
                    self.videos = res.videos ?? []
                }
            } catch {
                print("Failed to load channel: \(error)")
            }
        }
    }

    private func handleSubscribeToggle() {
        if api.account == nil {
            showAuthSheet = true
            return
        }
        Task {
            do {
                let res = try await api.toggleSubscribe(channelKey: channelKey)
                await MainActor.run {
                    self.isSubscribed = res.subscribed
                    self.subscribersCount = res.subscribers
                }
            } catch {
                print("Subscribe error: \(error)")
            }
        }
    }
}
