import SwiftUI

struct SettingsView: View {
    @EnvironmentObject var appState: AppState
    @State private var serverUrl: String = ""
    @State private var showLogoutAlert = false
    @State private var saved = false

    var body: some View {
        NavigationView {
            List {
                // Account section
                Section {
                    HStack(spacing: 14) {
                        ZStack {
                            Circle()
                                .fill(LinearGradient(colors: [Color("Accent"), Color("AccentSecondary")], startPoint: .topLeading, endPoint: .bottomTrailing))
                                .frame(width: 48, height: 48)
                            Image(systemName: "person.fill")
                                .foregroundColor(.white)
                                .font(.title3)
                        }
                        VStack(alignment: .leading, spacing: 3) {
                            Text(appState.appleIdMasked.isEmpty ? "Apple Account" : appState.appleIdMasked)
                                .font(.system(size: 15, weight: .semibold))
                                .foregroundColor(.primary)
                            Text("Đã đăng nhập")
                                .font(.caption)
                                .foregroundColor(.green)
                        }
                        Spacer()
                    }
                    .padding(.vertical, 4)
                } header: {
                    Text("Tài khoản")
                }

                // Server section
                Section {
                    VStack(alignment: .leading, spacing: 10) {
                        Label("URL Server", systemImage: "server.rack")
                            .font(.caption.weight(.semibold))
                            .foregroundColor(.secondary)
                        TextField("https://ipadl.storeios.net", text: $serverUrl)
                            .autocapitalization(.none)
                            .autocorrectionDisabled()
                            .keyboardType(.URL)
                            .font(.system(size: 14))
                    }

                    Button {
                        appState.serverURL = serverUrl.trimmingCharacters(in: .whitespaces)
                        withAnimation { saved = true }
                        DispatchQueue.main.asyncAfter(deadline: .now() + 2) {
                            withAnimation { saved = false }
                        }
                    } label: {
                        HStack {
                            Image(systemName: saved ? "checkmark.circle.fill" : "square.and.arrow.down")
                                .foregroundColor(saved ? .green : Color("Accent"))
                            Text(saved ? "Đã lưu!" : "Lưu cài đặt")
                                .foregroundColor(saved ? .green : Color("Accent"))
                                .font(.system(size: 15, weight: .semibold))
                        }
                    }
                } header: {
                    Text("Server")
                } footer: {
                    Text("Mặc định: https://ipadl.storeios.net")
                }

                // App Info section
                Section {
                    InfoRow(icon: "number.circle.fill", iconColor: .blue, title: "Phiên bản", value: "1.0.0")
                    InfoRow(icon: "iphone", iconColor: .gray, title: "Hỗ trợ iOS", value: "16.0+")
                    InfoRow(icon: "building.2.fill", iconColor: .purple, title: "Developer", value: "storeios.net")
                } header: {
                    Text("Thông tin ứng dụng")
                }

                // Danger section
                Section {
                    Button(role: .destructive) {
                        showLogoutAlert = true
                    } label: {
                        HStack {
                            Image(systemName: "rectangle.portrait.and.arrow.right")
                            Text("Đăng xuất")
                        }
                        .font(.system(size: 15, weight: .semibold))
                    }
                }
            }
            .navigationTitle("Cài đặt")
            .navigationBarTitleDisplayMode(.large)
            .onAppear { serverUrl = appState.serverURL }
            .alert("Đăng xuất?", isPresented: $showLogoutAlert) {
                Button("Huỷ", role: .cancel) {}
                Button("Đăng xuất", role: .destructive) { appState.logout() }
            } message: {
                Text("Bạn sẽ cần đăng nhập lại để sử dụng ứng dụng.")
            }
        }
    }
}

struct InfoRow: View {
    let icon: String
    let iconColor: Color
    let title: String
    let value: String

    var body: some View {
        HStack {
            Image(systemName: icon)
                .foregroundColor(iconColor)
                .frame(width: 26)
            Text(title)
                .foregroundColor(.primary)
            Spacer()
            Text(value)
                .foregroundColor(.secondary)
                .font(.system(size: 14))
        }
    }
}
