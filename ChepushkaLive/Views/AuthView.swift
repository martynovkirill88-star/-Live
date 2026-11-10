import SwiftUI

struct AuthView: View {
    @Environment(\.dismiss) private var dismiss
    @ObservedObject var api = APIService.shared

    @State private var code = "------"
    @State private var sessionId = ""
    @State private var pollToken = ""
    @State private var isPolling = false
    @State private var timer: Timer?

    var body: some View {
        NavigationView {
            VStack(spacing: 24) {
                Spacer()

                // Logo Circle
                Circle()
                    .fill(AppTheme.accent)
                    .frame(width: 80, height: 80)
                    .overlay(
                        Text("Ч")
                            .font(.system(size: 38, weight: .black))
                            .foregroundColor(AppTheme.accentDark)
                    )

                VStack(spacing: 8) {
                    Text("Вход в Чепушка Live")
                        .font(.system(size: 24, weight: .bold))
                        .foregroundColor(AppTheme.textPrimary)

                    Text("Для подписки, лайков и комментариев войдите в свой аккаунт")
                        .font(.system(size: 14))
                        .foregroundColor(AppTheme.textSecondary)
                        .multilineTextAlignment(.center)
                        .padding(.horizontal, 32)
                }

                // 6-digit code box
                VStack(spacing: 12) {
                    Text("Код авторизации:")
                        .font(.system(size: 13, weight: .semibold))
                        .foregroundColor(AppTheme.textSecondary)

                    HStack(spacing: 8) {
                        ForEach(0..<6, id: \.self) { idx in
                            let char = code.count > idx ? String(code[code.index(code.startIndex, offsetBy: idx)]) : "-"
                            Text(char)
                                .font(.system(size: 28, weight: .bold, design: .monospaced))
                                .foregroundColor(AppTheme.accent)
                                .frame(width: 44, height: 56)
                                .background(AppTheme.surface)
                                .cornerRadius(12)
                                .overlay(
                                    RoundedRectangle(cornerRadius: 12)
                                        .stroke(AppTheme.border, lineWidth: 1)
                                )
                        }
                    }

                    Text("Введите этот код на сайте live.chepushkavpn.fun в меню профиля «Войти на ТВ» или на телефоне")
                        .font(.system(size: 12))
                        .foregroundColor(AppTheme.textSecondary)
                        .multilineTextAlignment(.center)
                        .padding(.horizontal, 40)
                        .padding(.top, 4)
                }
                .padding(20)
                .background(AppTheme.surfaceAlt)
                .cornerRadius(16)
                .padding(.horizontal, 24)

                Spacer()

                Button(action: { dismiss() }) {
                    Text("Закрыть")
                        .font(.system(size: 16, weight: .bold))
                        .frame(maxWidth: .infinity)
                        .frame(height: 50)
                        .foregroundColor(AppTheme.textPrimary)
                        .background(AppTheme.surface)
                        .cornerRadius(25)
                }
                .padding(.horizontal, 24)
                .padding(.bottom, 20)
            }
            .background(AppTheme.background.ignoresSafeArea())
            .navigationBarTitleDisplayMode(.inline)
            .onAppear(perform: startSession)
            .onDisappear {
                timer?.invalidate()
                timer = nil
            }
        }
    }

    private func startSession() {
        Task {
            do {
                let res = try await api.startAuth()
                await MainActor.run {
                    self.sessionId = res.session_id
                    self.code = res.code
                    self.pollToken = res.poll_token
                    startPolling()
                }
            } catch {
                print("Failed to start auth session: \(error)")
            }
        }
    }

    private func startPolling() {
        timer?.invalidate()
        timer = Timer.scheduledTimer(withTimeInterval: 2.0, repeats: true) { _ in
            Task {
                do {
                    let res = try await api.pollAuth(sessionId: sessionId, pollToken: pollToken)
                    if res.status == "authorized", let acc = res.account {
                        await MainActor.run {
                            api.saveAccount(acc)
                            timer?.invalidate()
                            timer = nil
                            dismiss()
                        }
                    }
                } catch {
                    print("Poll error: \(error)")
                }
            }
        }
    }
}
