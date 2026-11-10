import SwiftUI

struct VideoCardView: View {
    let item: VideoItem
    let onChannelTap: () -> Void

    var body: some View {
        VStack(alignment: .leading, spacing: 10) {
            // Thumbnail container
            ZStack(alignment: .bottomTrailing) {
                AsyncImage(url: item.posterURL) { phase in
                    switch phase {
                    case .empty:
                        Rectangle()
                            .fill(AppTheme.surface)
                            .aspectRatio(16/9, contentMode: .fit)
                            .overlay(
                                ProgressView()
                                    .tint(AppTheme.accent)
                            )
                    case .success(let image):
                        image
                            .resizable()
                            .aspectRatio(16/9, contentMode: .fill)
                            .clipped()
                    case .failure:
                        Rectangle()
                            .fill(AppTheme.surface)
                            .aspectRatio(16/9, contentMode: .fit)
                            .overlay(
                                Image(systemName: "video.slash")
                                    .font(.system(size: 32))
                                    .foregroundColor(AppTheme.textSecondary)
                            )
                    @unknown default:
                        EmptyView()
                    }
                }
                .frame(maxWidth: .infinity)
                .cornerRadius(16)
                .overlay(
                    RoundedRectangle(cornerRadius: 16)
                        .stroke(AppTheme.border.opacity(0.6), lineWidth: 1)
                )

                // Duration badge or Live Badge
                if item.isLiveStream {
                    HStack(spacing: 4) {
                        Circle()
                            .fill(AppTheme.accentDark)
                            .frame(width: 6, height: 6)
                        Text("В ЭФИРЕ")
                            .font(.system(size: 11, weight: .bold))
                            .foregroundColor(AppTheme.accentDark)
                    }
                    .padding(.horizontal, 8)
                    .padding(.vertical, 4)
                    .background(AppTheme.accent)
                    .cornerRadius(6)
                    .padding(10)
                } else {
                    Text(item.formattedDuration)
                        .font(.system(size: 12, weight: .semibold))
                        .foregroundColor(AppTheme.textPrimary)
                        .padding(.horizontal, 8)
                        .padding(.vertical, 4)
                        .background(Color.black.opacity(0.85))
                        .cornerRadius(6)
                        .padding(10)
                }
            }

            // Info row (Avatar + Title + Meta)
            HStack(alignment: .top, spacing: 12) {
                // Channel Avatar
                Button(action: onChannelTap) {
                    if let avatarStr = item.channel_avatar, let avatarURL = URL(string: avatarStr.hasPrefix("http") ? avatarStr : "https://live.chepushkavpn.fun" + avatarStr) {
                        AsyncImage(url: avatarURL) { phase in
                            if let img = phase.image {
                                img.resizable().aspectRatio(contentMode: .fill)
                            } else {
                                DefaultAvatarView(name: item.displayChannel)
                            }
                        }
                        .frame(width: 40, height: 40)
                        .clipShape(Circle())
                    } else {
                        DefaultAvatarView(name: item.displayChannel)
                    }
                }
                .buttonStyle(PlainButtonStyle())

                // Title & Details
                VStack(alignment: .leading, spacing: 4) {
                    Text(item.displayTitle)
                        .font(.system(size: 15, weight: .bold))
                        .foregroundColor(AppTheme.textPrimary)
                        .lineLimit(2)
                        .multilineTextAlignment(.leading)

                    HStack(spacing: 4) {
                        Text(item.displayChannel)
                            .fontWeight(.medium)
                        Text("·")
                        Text(item.formattedViews)
                        Text("·")
                        Text(item.relativeTime)
                    }
                    .font(.system(size: 12))
                    .foregroundColor(AppTheme.textSecondary)
                    .lineLimit(1)
                }

                Spacer()

                // More Menu Button
                Menu {
                    Button(action: {}) {
                        Label("Поделиться", systemImage: "square.and.arrow.up")
                    }
                    Button(action: {}) {
                        Label("Сохранить", systemImage: "bookmark")
                    }
                } label: {
                    Image(systemName: "ellipsis")
                        .rotationEffect(.degrees(90))
                        .font(.system(size: 14, weight: .bold))
                        .foregroundColor(AppTheme.textSecondary)
                        .padding(6)
                }
            }
            .padding(.horizontal, 2)
        }
        .padding(.horizontal, 16)
        .padding(.vertical, 8)
    }
}

struct DefaultAvatarView: View {
    let name: String

    var body: some View {
        Circle()
            .fill(AppTheme.accent)
            .frame(width: 40, height: 40)
            .overlay(
                Text(String(name.prefix(1)).uppercased())
                    .font(.system(size: 16, weight: .bold))
                    .foregroundColor(AppTheme.accentDark)
            )
    }
}
