import SwiftUI
import AVKit

struct WatchVideoView: View {
    let video: VideoItem
    @Environment(\.dismiss) private var dismiss
    @ObservedObject var api = APIService.shared

    @State private var player: AVPlayer?
    @State private var isLiked = false
    @State private var isSaved = false
    @State private var likesCount = 42
    @State private var channelDetail: ChannelDetailResponse?
    @State private var isSubscribed = false
    @State private var subscribersCount = 0
    @State private var showChannelSheet = false
    @State private var showAuthSheet = false
    @State private var relatedVideos: [VideoItem] = []

    var body: some View {
        ScrollView {
            VStack(alignment: .leading, spacing: 0) {
                // Video Player Container
                ZStack {
                    if let player = player {
                        VideoPlayer(player: player)
                            .aspectRatio(16/9, contentMode: .fit)
                    } else {
                        Rectangle()
                            .fill(Color.black)
                            .aspectRatio(16/9, contentMode: .fit)
                            .overlay(
                                ProgressView()
                                    .tint(AppTheme.accent)
                            )
                    }
                }
                .frame(maxWidth: .infinity)
                .background(Color.black)

                // Video Meta Section
                VStack(alignment: .leading, spacing: 14) {
                    Text(video.displayTitle)
                        .font(.system(size: 18, weight: .bold))
                        .foregroundColor(AppTheme.textPrimary)
                        .lineLimit(3)

                    HStack(spacing: 6) {
                        Text(video.formattedViews)
                        Text("·")
                        Text(video.relativeTime)
                        if video.isLiveStream {
                            Text("·")
                            Text("Прямой эфир")
                                .foregroundColor(AppTheme.accent)
                                .fontWeight(.bold)
                        }
                    }
                    .font(.system(size: 13))
                    .foregroundColor(AppTheme.textSecondary)

                    // Action Buttons Row (Like, Dislike, Share, Save)
                    ScrollView(.horizontal, showsIndicators: false) {
                        HStack(spacing: 12) {
                            // Like & Dislike capsule
                            HStack(spacing: 0) {
                                Button(action: {
                                    isLiked.toggle()
                                    likesCount += isLiked ? 1 : -1
                                }) {
                                    HStack(spacing: 6) {
                                        Image(systemName: isLiked ? "hand.thumbsup.fill" : "hand.thumbsup")
                                            .foregroundColor(isLiked ? AppTheme.accent : AppTheme.textPrimary)
                                        Text("\(likesCount)")
                                            .font(.system(size: 13, weight: .semibold))
                                            .foregroundColor(isLiked ? AppTheme.accent : AppTheme.textPrimary)
                                    }
                                    .padding(.horizontal, 14)
                                    .padding(.vertical, 8)
                                }

                                Divider()
                                    .frame(height: 18)
                                    .background(AppTheme.border)

                                Button(action: {}) {
                                    Image(systemName: "hand.thumbsdown")
                                        .foregroundColor(AppTheme.textPrimary)
                                        .padding(.horizontal, 12)
                                        .padding(.vertical, 8)
                                }
                            }
                            .background(AppTheme.surface)
                            .cornerRadius(20)

                            // Share button
                            Button(action: {
                                shareVideo()
                            }) {
                                HStack(spacing: 6) {
                                    Image(systemName: "square.and.arrow.up")
                                    Text("Поделиться")
                                        .font(.system(size: 13, weight: .semibold))
                                }
                                .foregroundColor(AppTheme.textPrimary)
                                .padding(.horizontal, 14)
                                .padding(.vertical, 8)
                                .background(AppTheme.surface)
                                .cornerRadius(20)
                            }

                            // Save button
                            Button(action: {
                                isSaved.toggle()
                                api.toggleFavorite(video.id)
                            }) {
                                HStack(spacing: 6) {
                                    Image(systemName: isSaved ? "bookmark.fill" : "bookmark")
                                        .foregroundColor(isSaved ? AppTheme.accent : AppTheme.textPrimary)
                                    Text("В закладки")
                                        .font(.system(size: 13, weight: .semibold))
                                        .foregroundColor(isSaved ? AppTheme.accent : AppTheme.textPrimary)
                                }
                                .padding(.horizontal, 14)
                                .padding(.vertical, 8)
                                .background(AppTheme.surface)
                                .cornerRadius(20)
                            }
                        }
                    }

                    Divider()
                        .background(AppTheme.border)

                    // Channel Bar
                    HStack(spacing: 12) {
                        Button(action: { showChannelSheet = true }) {
                            HStack(spacing: 12) {
                                DefaultAvatarView(name: video.displayChannel)

                                VStack(alignment: .leading, spacing: 2) {
                                    HStack(spacing: 4) {
                                        Text(video.displayChannel)
                                            .font(.system(size: 15, weight: .bold))
                                            .foregroundColor(AppTheme.textPrimary)
                                        Image(systemName: "checkmark.seal.fill")
                                            .font(.system(size: 12))
                                            .foregroundColor(AppTheme.accent)
                                    }
                                    Text(subscribersText)
                                        .font(.system(size: 12))
                                        .foregroundColor(AppTheme.textSecondary)
                                }
                            }
                        }
                        .buttonStyle(PlainButtonStyle())

                        Spacer()

                        // Subscribe button
                        Button(action: handleSubscribeToggle) {
                            HStack(spacing: 6) {
                                if isSubscribed {
                                    Image(systemName: "checkmark")
                                        .font(.system(size: 12, weight: .bold))
                                    Text("Вы подписаны")
                                        .font(.system(size: 13, weight: .bold))
                                } else {
                                    Text("Подписаться")
                                        .font(.system(size: 13, weight: .bold))
                                }
                            }
                            .padding(.horizontal, 16)
                            .padding(.vertical, 8)
                            .foregroundColor(isSubscribed ? AppTheme.textPrimary : AppTheme.accentDark)
                            .background(isSubscribed ? AppTheme.surface : AppTheme.accent)
                            .cornerRadius(18)
                            .overlay(
                                RoundedRectangle(cornerRadius: 18)
                                    .stroke(isSubscribed ? AppTheme.accent : Color.clear, lineWidth: 1)
                            )
                        }
                    }

                    Divider()
                        .background(AppTheme.border)

                    // Description snippet
                    if let desc = video.description, !desc.isEmpty {
                        VStack(alignment: .leading, spacing: 6) {
                            Text("Описание")
                                .font(.system(size: 14, weight: .bold))
                                .foregroundColor(AppTheme.textPrimary)
                            Text(desc)
                                .font(.system(size: 13))
                                .foregroundColor(AppTheme.textSecondary)
                                .lineLimit(4)
                        }
                        .padding(12)
                        .frame(maxWidth: .infinity, alignment: .leading)
                        .background(AppTheme.surfaceAlt)
                        .cornerRadius(12)
                    }

                    // Up Next / Related videos
                    Text("Следующие видео")
                        .font(.system(size: 16, weight: .bold))
                        .foregroundColor(AppTheme.textPrimary)
                        .padding(.top, 10)
                }
                .padding(16)

                // Related video items
                LazyVStack(spacing: 8) {
                    ForEach(relatedVideos.filter { $0.id != video.id }) { item in
                        VideoCardView(item: item, onChannelTap: {
                            showChannelSheet = true
                        })
                    }
                }
            }
        }
        .background(AppTheme.background.ignoresSafeArea())
        .navigationBarTitleDisplayMode(.inline)
        .toolbar {
            ToolbarItem(placement: .navigationBarTrailing) {
                Button(action: { dismiss() }) {
                    Image(systemName: "xmark.circle.fill")
                        .font(.system(size: 20))
                        .foregroundColor(AppTheme.textSecondary)
                }
            }
        }
        .onAppear {
            setupPlayer()
            loadChannelInfo()
            isSaved = api.favorites.contains(video.id)
        }
        .onDisappear {
            player?.pause()
            player = nil
        }
        .sheet(isPresented: $showChannelSheet) {
            ChannelProfileView(channelKey: video.channel_id ?? "3c64885adcbc456590c31ad7e8d2dfc5", channelName: video.displayChannel)
        }
        .sheet(isPresented: $showAuthSheet) {
            AuthView()
        }
    }

    private var subscribersText: String {
        let s = subscribersCount
        if s == 1 { return "1 подписчик" }
        if s >= 2 && s <= 4 { return "\(s) подписчика" }
        return "\(s) подписчиков"
    }

    private func setupPlayer() {
        guard let url = video.streamURL else { return }
        let playerItem = AVPlayerItem(url: url)
        let avPlayer = AVPlayer(playerItem: playerItem)
        self.player = avPlayer
        avPlayer.play()
    }

    private func loadChannelInfo() {
        let chKey = video.channel_id ?? "3c64885adcbc456590c31ad7e8d2dfc5"
        Task {
            do {
                let res = try await api.fetchChannel(key: chKey)
                await MainActor.run {
                    self.channelDetail = res
                    self.isSubscribed = res.subscribed == true || api.localSubscriptions.contains(chKey)
                    self.subscribersCount = res.subscribers ?? 0
                    self.relatedVideos = res.videos ?? []
                }
            } catch {
                print("Failed to fetch channel details: \(error)")
            }
        }
    }

    private func handleSubscribeToggle() {
        if api.account == nil {
            showAuthSheet = true
            return
        }
        let chKey = video.channel_id ?? "3c64885adcbc456590c31ad7e8d2dfc5"
        Task {
            do {
                let res = try await api.toggleSubscribe(channelKey: chKey)
                await MainActor.run {
                    self.isSubscribed = res.subscribed
                    self.subscribersCount = res.subscribers
                }
            } catch {
                print("Subscribe error: \(error)")
            }
        }
    }

    private func shareVideo() {
        guard let url = URL(string: "https://live.chepushkavpn.fun/watch/\(video.id)") else { return }
        let av = UIActivityViewController(activityItems: [video.displayTitle, url], applicationActivities: nil)
        if let windowScene = UIApplication.shared.connectedScenes.first as? UIWindowScene,
           let rootVC = windowScene.windows.first?.rootViewController {
            rootVC.present(av, animated: true, completion: nil)
        }
    }
}
