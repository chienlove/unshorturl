import SwiftUI

struct DownloadView: View {
    @EnvironmentObject var appState: AppState
    @State private var appInput = ""
    @State private var versionId = ""
    @State private var isLoading = false
    @State private var errorMsg = ""
    @State private var showVersionField = false

    private var api: APIService { APIService(baseURL: appState.serverURL) }

    var body: some View {
        NavigationView {
            ScrollView {
                VStack(spacing: 20) {

                    // Input Card
                    inputCard
                        .padding(.horizontal, 16)
                        .padding(.top, 8)

                    // Status Section
                    switch appState.downloadStatus {
                    case .idle:
                        EmptyView()
                    case .pending:
                        ProgressCardView(progress: 0, message: "Đang kết nối...", detail: "Vui lòng chờ", steps: appState.progressSteps)
                            .padding(.horizontal, 16)
                    case .downloading(let progress, let message, let detail):
                        ProgressCardView(progress: progress, message: message, detail: detail, steps: appState.progressSteps)
                            .padding(.horizontal, 16)
                    case .done(let info, let downloadUrl, let otaUrl):
                        ResultCard(info: info, downloadUrl: downloadUrl, otaUrl: otaUrl)
                            .padding(.horizontal, 16)
                    case .error(let msg):
                        ErrorCard(message: msg) {
                            appState.resetDownload()
                        }
                        .padding(.horizontal, 16)
                    }

                    Spacer(minLength: 20)
                }
            }
            .background(Color("BG"))
            .navigationTitle("Tải IPA")
            .navigationBarTitleDisplayMode(.large)
            .toolbar {
                if appState.downloadStatus != .idle {
                    ToolbarItem(placement: .navigationBarTrailing) {
                        Button("Làm mới") { appState.resetDownload(); appInput = ""; versionId = "" }
                            .foregroundColor(Color("Accent"))
                    }
                }
            }
        }
    }

    // MARK: - Input Card

    var inputCard: some View {
        VStack(alignment: .leading, spacing: 16) {
            Label("Thông tin ứng dụng", systemImage: "magnifyingglass")
                .font(.system(size: 14, weight: .semibold))
                .foregroundColor(.secondary)

            IPADLTextField(
                icon: "app.badge",
                placeholder: "App ID hoặc link App Store",
                text: $appInput
            )

            // Toggle version field
            Button {
                withAnimation(.spring(response: 0.3)) { showVersionField.toggle() }
            } label: {
                HStack(spacing: 6) {
                    Image(systemName: showVersionField ? "minus.circle" : "plus.circle")
                        .font(.caption)
                    Text(showVersionField ? "Ẩn phiên bản" : "Tải phiên bản cũ (tùy chọn)")
                        .font(.caption)
                }
                .foregroundColor(Color("Accent"))
            }

            if showVersionField {
                IPADLTextField(
                    icon: "tag.fill",
                    placeholder: "Version ID (để trống = mới nhất)",
                    text: $versionId,
                    keyboardType: .numberPad
                )
                .transition(.move(edge: .top).combined(with: .opacity))
            }

            // Error
            if !errorMsg.isEmpty {
                HStack(spacing: 8) {
                    Image(systemName: "exclamationmark.triangle.fill").foregroundColor(.orange).font(.caption)
                    Text(errorMsg).font(.caption).foregroundColor(.orange)
                }
            }

            // Download Button
            Button {
                Task { await startDownload() }
            } label: {
                HStack(spacing: 10) {
                    if isLoading {
                        ProgressView().tint(.white).scaleEffect(0.85)
                    } else {
                        Image(systemName: "arrow.down.circle.fill")
                    }
                    Text(isLoading ? "Đang chuẩn bị..." : "Tải xuống")
                        .font(.system(size: 16, weight: .bold))
                }
                .foregroundColor(.white)
                .frame(maxWidth: .infinity)
                .frame(height: 52)
                .background(
                    LinearGradient(colors: isLoading ? [.gray] : [Color("Accent"), Color("AccentSecondary")],
                                   startPoint: .leading, endPoint: .trailing)
                )
                .clipShape(RoundedRectangle(cornerRadius: 14))
                .shadow(color: isLoading ? .clear : Color("Accent").opacity(0.3), radius: 10, y: 4)
            }
            .disabled(isLoading || appInput.trimmingCharacters(in: .whitespaces).isEmpty)
        }
        .padding(20)
        .background(Color("Card"))
        .clipShape(RoundedRectangle(cornerRadius: 20))
    }

    // MARK: - Actions

    func startDownload() async {
        let cleanInput = appInput.trimmingCharacters(in: .whitespaces)
        guard !cleanInput.isEmpty else { return }

        // Extract numeric App ID from App Store URL if needed
        let appId: String
        if let match = cleanInput.range(of: #"/id(\d+)"#, options: .regularExpression) {
            appId = String(cleanInput[match]).replacingOccurrences(of: "/id", with: "")
        } else {
            appId = cleanInput
        }

        isLoading = true
        errorMsg = ""
        appState.downloadStatus = .pending
        appState.progressSteps = []

        guard let token = await api.getPurchaseToken() else {
            isLoading = false
            errorMsg = "Lỗi phiên. Vui lòng đăng nhập lại."
            appState.downloadStatus = .error(message: "Session error")
            return
        }

        let resp = await api.startDownload(
            appId: appId,
            appVerId: versionId.isEmpty ? nil : versionId,
            deviceId: appState.deviceId,
            purchaseToken: token
        )

        isLoading = false

        if let requestId = resp?.requestId, resp?.success == true {
            appState.startPolling(requestId: requestId)
        } else if resp?.require2FA == true {
            appState.isLoggedIn = false
            appState.downloadStatus = .idle
        } else {
            let msg = resp?.error ?? "Không thể bắt đầu tải. Thử lại."
            errorMsg = msg
            appState.downloadStatus = .error(message: msg)
        }
    }
}

// MARK: - Error Card

struct ErrorCard: View {
    let message: String
    let onRetry: () -> Void

    var body: some View {
        VStack(spacing: 16) {
            Image(systemName: "xmark.circle.fill")
                .font(.system(size: 44))
                .foregroundColor(.red)

            Text("Tải thất bại")
                .font(.headline)
                .foregroundColor(.primary)

            Text(message)
                .font(.subheadline)
                .foregroundColor(.secondary)
                .multilineTextAlignment(.center)

            Button("Thử lại", action: onRetry)
                .font(.system(size: 15, weight: .semibold))
                .foregroundColor(.white)
                .padding(.horizontal, 32)
                .padding(.vertical, 12)
                .background(Color.red.opacity(0.85))
                .clipShape(Capsule())
        }
        .frame(maxWidth: .infinity)
        .padding(24)
        .background(Color("Card"))
        .clipShape(RoundedRectangle(cornerRadius: 20))
    }
}

// MARK: - Result Card

struct ResultCard: View {
    let info: AppInfo
    let downloadUrl: String
    let otaUrl: String?

    var body: some View {
        VStack(spacing: 20) {
            // Success header
            HStack(spacing: 10) {
                Image(systemName: "checkmark.circle.fill")
                    .foregroundColor(.green)
                    .font(.title2)
                Text("Tải thành công!")
                    .font(.headline)
                    .foregroundColor(.primary)
            }

            // App info
            HStack(spacing: 14) {
                AsyncImage(url: URL(string: info.icon ?? "")) { img in
                    img.resizable().scaledToFill()
                } placeholder: {
                    RoundedRectangle(cornerRadius: 12)
                        .fill(Color("FieldBG"))
                        .overlay(Image(systemName: "app.fill").foregroundColor(.secondary))
                }
                .frame(width: 60, height: 60)
                .clipShape(RoundedRectangle(cornerRadius: 14))

                VStack(alignment: .leading, spacing: 4) {
                    Text(info.name ?? "Unknown App")
                        .font(.system(size: 16, weight: .bold))
                        .foregroundColor(.primary)
                        .lineLimit(1)
                    Text(info.artistName ?? "Unknown Developer")
                        .font(.caption)
                        .foregroundColor(.secondary)

                    HStack(spacing: 10) {
                        if let ver = info.version {
                            StatPill(icon: "tag.fill", text: ver, color: Color("Accent"))
                        }
                        if let size = info.size {
                            StatPill(icon: "externaldrive.fill", text: size, color: .purple)
                        }
                        if let os = info.minOS {
                            StatPill(icon: "iphone", text: "iOS \(os)+", color: .orange)
                        }
                    }
                }
            }
            .frame(maxWidth: .infinity, alignment: .leading)
            .padding(14)
            .background(Color("FieldBG"))
            .clipShape(RoundedRectangle(cornerRadius: 14))

            // Action Buttons
            VStack(spacing: 10) {
                if let ota = otaUrl, let url = URL(string: ota) {
                    Link(destination: url) {
                        HStack {
                            Image(systemName: "iphone.circle.fill")
                            Text("Cài đặt trực tiếp (OTA)")
                                .font(.system(size: 15, weight: .bold))
                        }
                        .foregroundColor(.white)
                        .frame(maxWidth: .infinity)
                        .frame(height: 50)
                        .background(LinearGradient(colors: [.green, .teal], startPoint: .leading, endPoint: .trailing))
                        .clipShape(RoundedRectangle(cornerRadius: 14))
                    }
                }

                if let url = URL(string: downloadUrl) {
                    Link(destination: url) {
                        HStack {
                            Image(systemName: "arrow.down.circle")
                            Text("Tải file IPA")
                                .font(.system(size: 15, weight: .bold))
                        }
                        .foregroundColor(Color("Accent"))
                        .frame(maxWidth: .infinity)
                        .frame(height: 50)
                        .background(Color("Accent").opacity(0.12))
                        .clipShape(RoundedRectangle(cornerRadius: 14))
                        .overlay(RoundedRectangle(cornerRadius: 14).stroke(Color("Accent").opacity(0.3), lineWidth: 1))
                    }
                }
            }
        }
        .padding(20)
        .background(Color("Card"))
        .clipShape(RoundedRectangle(cornerRadius: 20))
    }
}

struct StatPill: View {
    let icon: String
    let text: String
    let color: Color

    var body: some View {
        HStack(spacing: 4) {
            Image(systemName: icon).font(.system(size: 9))
            Text(text).font(.system(size: 11, weight: .medium))
        }
        .foregroundColor(color)
        .padding(.horizontal, 8)
        .padding(.vertical, 4)
        .background(color.opacity(0.12))
        .clipShape(Capsule())
    }
}
