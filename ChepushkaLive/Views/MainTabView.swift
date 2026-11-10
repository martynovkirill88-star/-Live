import SwiftUI

struct MainTabView: View {
    @ObservedObject var api = APIService.shared
    @State private var selectedTab = 0
    @State private var showAuthSheet = false

    var body: some View {
        TabView(selection: $selectedTab) {
            HomeFeedView()
                .tabItem {
                    Image(systemName: selectedTab == 0 ? "house.fill" : "house")
                    Text("Главная")
                }
                .tag(0)

            LiveStreamsView()
                .tabItem {
                    Image(systemName: "dot.radiowaves.left.and.right")
                    Text("Эфиры")
                }
                .tag(1)

            CreateMediaPlaceholderView()
                .tabItem {
                    Image(systemName: "plus.circle.fill")
                    Text("Добавить")
                }
                .tag(2)

            FavoritesView()
                .tabItem {
                    Image(systemName: selectedTab == 3 ? "bookmark.fill" : "bookmark")
                    Text("Избранное")
                }
                .tag(3)

            ProfileTabView()
                .tabItem {
                    Image(systemName: selectedTab == 4 ? "person.fill" : "person")
                    Text("Профиль")
                }
                .tag(4)
        }
        .accentColor(AppTheme.accent)
        .onAppear {
            let appearance = UITabBarAppearance()
            appearance.configureWithOpaqueBackground()
            appearance.backgroundColor = UIColor(AppTheme.background)
            UITabBar.appearance().standardAppearance = appearance
            if #available(iOS 15.0, *) {
                UITabBar.appearance().scrollEdgeAppearance = appearance
            }
        }
    }
}

struct LiveStreamsView: View {
    @ObservedObject var api = APIService.shared
    @State private var lives: [VideoItem] = []
    @State private var selectedVideo: VideoItem?

    var body: some View {
        NavigationView {
            VStack {
                if lives.isEmpty {
                    VStack(spacing: 12) {
                        Image(systemName: "dot.radiowaves.left.and.right")
                            .font(.system(size: 48))
                            .foregroundColor(AppTheme.textSecondary)
                        Text("Сейчас нет активных прямых эфиров")
                            .font(.system(size: 16, weight: .bold))
                            .foregroundColor(AppTheme.textPrimary)
                    }
                } else {
                    ScrollView {
                        LazyVStack(spacing: 8) {
                            ForEach(lives) { item in
                                Button(action: { selectedVideo = item }) {
                                    VideoCardView(item: item, onChannelTap: {})
                                }
                                .buttonStyle(PlainButtonStyle())
                            }
                        }
                    }
                }
            }
            .frame(maxWidth: .infinity, maxHeight: .infinity)
            .background(AppTheme.background.ignoresSafeArea())
            .navigationTitle("Прямые эфиры")
            .navigationBarTitleDisplayMode(.inline)
            .onAppear(perform: loadLives)
            .fullScreenCover(item: $selectedVideo) { v in
                WatchVideoView(video: v)
            }
        }
    }

    private func loadLives() {
        Task {
            if let list = try? await api.fetchCatalog() {
                await MainActor.run {
                    self.lives = list.filter { $0.isLiveStream }
                }
            }
        }
    }
}

struct CreateMediaPlaceholderView: View {
    var body: some View {
        VStack(spacing: 16) {
            Image(systemName: "video.badge.plus")
                .font(.system(size: 54))
                .foregroundColor(AppTheme.accent)
            Text("Загрузка видео и эфиров")
                .font(.system(size: 20, weight: .bold))
                .foregroundColor(AppTheme.textPrimary)
            Text("Публикация видео доступна через веб-платформу live.chepushkavpn.fun")
                .font(.system(size: 14))
                .foregroundColor(AppTheme.textSecondary)
                .multilineTextAlignment(.center)
                .padding(.horizontal, 32)
        }
        .frame(maxWidth: .infinity, maxHeight: .infinity)
        .background(AppTheme.background.ignoresSafeArea())
    }
}

struct FavoritesView: View {
    @ObservedObject var api = APIService.shared
    @State private var favVideos: [VideoItem] = []
    @State private var selectedVideo: VideoItem?

    var body: some View {
        NavigationView {
            VStack {
                if favVideos.isEmpty {
                    VStack(spacing: 12) {
                        Image(systemName: "bookmark")
                            .font(.system(size: 48))
                            .foregroundColor(AppTheme.textSecondary)
                        Text("Нет сохранённых видео")
                            .font(.system(size: 16, weight: .bold))
                            .foregroundColor(AppTheme.textPrimary)
                        Text("Нажимайте «В закладки» во время просмотра видео")
                            .font(.system(size: 13))
                            .foregroundColor(AppTheme.textSecondary)
                    }
                } else {
                    ScrollView {
                        LazyVStack(spacing: 8) {
                            ForEach(favVideos) { item in
                                Button(action: { selectedVideo = item }) {
                                    VideoCardView(item: item, onChannelTap: {})
                                }
                                .buttonStyle(PlainButtonStyle())
                            }
                        }
                    }
                }
            }
            .frame(maxWidth: .infinity, maxHeight: .infinity)
            .background(AppTheme.background.ignoresSafeArea())
            .navigationTitle("Избранное")
            .navigationBarTitleDisplayMode(.inline)
            .onAppear(perform: loadFavs)
            .fullScreenCover(item: $selectedVideo) { v in
                WatchVideoView(video: v)
            }
        }
    }

    private func loadFavs() {
        Task {
            if let list = try? await api.fetchCatalog() {
                await MainActor.run {
                    self.favVideos = list.filter { api.favorites.contains($0.id) }
                }
            }
        }
    }
}

struct ProfileTabView: View {
    @ObservedObject var api = APIService.shared
    @State private var showAuthSheet = false

    var body: some View {
        NavigationView {
            VStack(spacing: 24) {
                if let acc = api.account {
                    VStack(spacing: 16) {
                        Circle()
                            .fill(AppTheme.accent)
                            .frame(width: 80, height: 80)
                            .overlay(
                                Text(String(acc.name?.prefix(1) ?? "U").uppercased())
                                    .font(.system(size: 32, weight: .black))
                                    .foregroundColor(AppTheme.accentDark)
                            )

                        VStack(spacing: 4) {
                            Text(acc.name ?? "Пользователь")
                                .font(.system(size: 22, weight: .bold))
                                .foregroundColor(AppTheme.textPrimary)
                            if let uname = acc.username, !uname.isEmpty {
                                Text("@\(uname)")
                                    .font(.system(size: 14))
                                    .foregroundColor(AppTheme.textSecondary)
                            }
                            Text(acc.role == "admin" ? "Администратор" : "Зритель")
                                .font(.system(size: 12, weight: .semibold))
                                .foregroundColor(AppTheme.accent)
                                .padding(.horizontal, 10)
                                .padding(.vertical, 4)
                                .background(AppTheme.surfaceAlt)
                                .cornerRadius(8)
                                .padding(.top, 4)
                        }
                    }
                    .padding(.top, 40)

                    Spacer()

                    Button(action: {
                        api.saveAccount(nil)
                    }) {
                        Text("Выйти из аккаунта")
                            .font(.system(size: 16, weight: .bold))
                            .frame(maxWidth: .infinity)
                            .frame(height: 50)
                            .foregroundColor(AppTheme.danger)
                            .background(AppTheme.surface)
                            .cornerRadius(25)
                    }
                    .padding(.horizontal, 24)
                    .padding(.bottom, 20)
                } else {
                    Spacer()
                    VStack(spacing: 16) {
                        Image(systemName: "person.crop.circle.badge.questionmark")
                            .font(.system(size: 64))
                            .foregroundColor(AppTheme.textSecondary)
                        Text("Вы не вошли в аккаунт")
                            .font(.system(size: 20, weight: .bold))
                            .foregroundColor(AppTheme.textPrimary)
                        Text("Войдите для подписки на каналы, отметок «Нравится» и сохранения истории")
                            .font(.system(size: 14))
                            .foregroundColor(AppTheme.textSecondary)
                            .multilineTextAlignment(.center)
                            .padding(.horizontal, 32)

                        Button(action: { showAuthSheet = true }) {
                            Text("Войти в аккаунт")
                                .font(.system(size: 16, weight: .bold))
                                .frame(maxWidth: .infinity)
                                .frame(height: 50)
                                .foregroundColor(AppTheme.accentDark)
                                .background(AppTheme.accent)
                                .cornerRadius(25)
                        }
                        .padding(.horizontal, 24)
                        .padding(.top, 16)
                    }
                    Spacer()
                }
            }
            .frame(maxWidth: .infinity, maxHeight: .infinity)
            .background(AppTheme.background.ignoresSafeArea())
            .navigationTitle("Профиль")
            .navigationBarTitleDisplayMode(.inline)
            .sheet(isPresented: $showAuthSheet) {
                AuthView()
            }
        }
    }
}
