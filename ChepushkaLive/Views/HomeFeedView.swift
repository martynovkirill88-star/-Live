import SwiftUI

struct HomeFeedView: View {
    @ObservedObject var api = APIService.shared

    @State private var videos: [VideoItem] = []
    @State private var isLoading = false
    @State private var activeCategory = "all"
    @State private var searchQuery = ""
    @State private var isSearchActive = false
    @State private var selectedVideo: VideoItem?
    @State private var selectedChannelKey: String?
    @State private var selectedChannelName: String?
    @State private var showAuthSheet = false

    let categories = [
        CategoryItem(id: "all", label: "Все", icon: "square.grid.2x2"),
        CategoryItem(id: "live", label: "Прямой эфир", icon: "dot.radiowaves.left.and.right"),
        CategoryItem(id: "tech", label: "Технологии", icon: "laptopcomputer"),
        CategoryItem(id: "music", label: "Музыка", icon: "music.note"),
        CategoryItem(id: "travel", label: "Путешествия", icon: "airplane"),
        CategoryItem(id: "games", label: "Игры", icon: "gamecontroller"),
        CategoryItem(id: "podcasts", label: "Подкасты", icon: "mic")
    ]

    var filteredVideos: [VideoItem] {
        videos.filter { item in
            if activeCategory == "live" && !item.isLiveStream { return false }
            if activeCategory != "all" && activeCategory != "live" {
                let text = ((item.title ?? "") + " " + (item.description ?? "")).lowercased()
                if activeCategory == "music" && !text.contains("музык") && !text.contains("клип") { return false }
                if activeCategory == "travel" && !text.contains("путешеств") && !text.contains("обзор") { return false }
                if activeCategory == "games" && !text.contains("игр") && !text.contains("стрим") { return false }
                if activeCategory == "podcasts" && !text.contains("подкаст") && !text.contains("разговор") { return false }
            }
            if !searchQuery.isEmpty {
                let q = searchQuery.lowercased()
                let titleMatch = (item.title ?? "").lowercased().contains(q)
                let channelMatch = (item.channel ?? "").lowercased().contains(q)
                return titleMatch || channelMatch
            }
            return true
        }
    }

    var body: some View {
        VStack(spacing: 0) {
            // Top Navigation Bar matching Mockup
            HStack(spacing: 12) {
                // Logo: (C) + Чепушка Live
                HStack(spacing: 8) {
                    Circle()
                        .fill(AppTheme.accent)
                        .frame(width: 32, height: 32)
                        .overlay(
                            Text("Ч")
                                .font(.system(size: 16, weight: .black))
                                .foregroundColor(AppTheme.accentDark)
                        )

                    HStack(spacing: 4) {
                        Text("Чепушка")
                            .font(.system(size: 20, weight: .black))
                            .foregroundColor(AppTheme.textPrimary)
                        Text("Live")
                            .font(.system(size: 20, weight: .black))
                            .foregroundColor(AppTheme.accent)
                    }
                }

                Spacer()

                // Search Icon
                Button(action: { isSearchActive.toggle() }) {
                    Image(systemName: "magnifyingglass")
                        .font(.system(size: 18, weight: .semibold))
                        .foregroundColor(AppTheme.textPrimary)
                        .frame(width: 38, height: 38)
                        .background(AppTheme.surface)
                        .clipShape(Circle())
                }

                // Account / Login Icon
                Button(action: { showAuthSheet = true }) {
                    if let acc = api.account {
                        Circle()
                            .fill(AppTheme.accent)
                            .frame(width: 38, height: 38)
                            .overlay(
                                Text(String(acc.name?.prefix(1) ?? "U").uppercased())
                                    .font(.system(size: 16, weight: .bold))
                                    .foregroundColor(AppTheme.accentDark)
                            )
                    } else {
                        Image(systemName: "person.crop.circle")
                            .font(.system(size: 20))
                            .foregroundColor(AppTheme.textPrimary)
                            .frame(width: 38, height: 38)
                            .background(AppTheme.surface)
                            .clipShape(Circle())
                    }
                }
            }
            .padding(.horizontal, 16)
            .padding(.vertical, 10)
            .background(AppTheme.background)

            // Search Bar (if active)
            if isSearchActive {
                HStack {
                    Image(systemName: "magnifyingglass")
                        .foregroundColor(AppTheme.textSecondary)
                    TextField("Поиск видео и каналов...", text: $searchQuery)
                        .foregroundColor(AppTheme.textPrimary)
                    if !searchQuery.isEmpty {
                        Button(action: { searchQuery = "" }) {
                            Image(systemName: "xmark.circle.fill")
                                .foregroundColor(AppTheme.textSecondary)
                        }
                    }
                }
                .padding(.horizontal, 12)
                .padding(.vertical, 8)
                .background(AppTheme.surface)
                .cornerRadius(10)
                .padding(.horizontal, 16)
                .padding(.bottom, 8)
            }

            // Category Chips Row
            ScrollView(.horizontal, showsIndicators: false) {
                HStack(spacing: 8) {
                    ForEach(categories) { cat in
                        let isSelected = activeCategory == cat.id
                        Button(action: { activeCategory = cat.id }) {
                            Text(cat.label)
                                .font(.system(size: 14, weight: .bold))
                                .padding(.horizontal, 16)
                                .padding(.vertical, 8)
                                .foregroundColor(isSelected ? AppTheme.accentDark : AppTheme.textPrimary)
                                .background(isSelected ? AppTheme.accent : AppTheme.surface)
                                .cornerRadius(16)
                        }
                    }
                }
                .padding(.horizontal, 16)
                .padding(.vertical, 6)
            }

            Divider()
                .background(AppTheme.border)

            // Main Video Feed
            if isLoading && videos.isEmpty {
                Spacer()
                ProgressView()
                    .tint(AppTheme.accent)
                Spacer()
            } else if filteredVideos.isEmpty {
                Spacer()
                VStack(spacing: 12) {
                    Image(systemName: "play.rectangle")
                        .font(.system(size: 48))
                        .foregroundColor(AppTheme.textSecondary)
                    Text("В этом разделе пока нет видео")
                        .font(.system(size: 16, weight: .bold))
                        .foregroundColor(AppTheme.textPrimary)
                    Text("Выберите другую категорию")
                        .font(.system(size: 13))
                        .foregroundColor(AppTheme.textSecondary)
                }
                Spacer()
            } else {
                ScrollView {
                    LazyVStack(spacing: 8) {
                        ForEach(filteredVideos) { item in
                            Button(action: { selectedVideo = item }) {
                                VideoCardView(item: item, onChannelTap: {
                                    selectedChannelKey = item.channel_id ?? "3c64885adcbc456590c31ad7e8d2dfc5"
                                    selectedChannelName = item.displayChannel
                                })
                            }
                            .buttonStyle(PlainButtonStyle())
                        }
                    }
                    .padding(.vertical, 8)
                }
                .refreshable {
                    await loadCatalog()
                }
            }
        }
        .background(AppTheme.background.ignoresSafeArea())
        .onAppear {
            Task { await loadCatalog() }
        }
        .fullScreenCover(item: $selectedVideo) { v in
            WatchVideoView(video: v)
        }
        .sheet(item: Binding<ChannelItemIdentifiable?>(
            get: {
                if let key = selectedChannelKey, let name = selectedChannelName {
                    return ChannelItemIdentifiable(key: key, name: name)
                }
                return nil
            },
            set: { val in
                selectedChannelKey = val?.key
                selectedChannelName = val?.name
            }
        )) { ch in
            ChannelProfileView(channelKey: ch.key, channelName: ch.name)
        }
        .sheet(isPresented: $showAuthSheet) {
            AuthView()
        }
    }

    private func loadCatalog() async {
        isLoading = true
        do {
            let res = try await api.fetchCatalog()
            await MainActor.run {
                self.videos = res
                self.isLoading = false
            }
        } catch {
            print("Failed to load catalog: \(error)")
            await MainActor.run { self.isLoading = false }
        }
    }
}

struct ChannelItemIdentifiable: Identifiable {
    var id: String { key }
    let key: String
    let name: String
}
