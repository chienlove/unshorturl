import SwiftUI

struct PurchaseView: View {
    @EnvironmentObject var appState: AppState
    @State private var appInput = ""
    @State private var isLoading = false
    @State private var result: PurchaseResult? = nil
    @State private var errorMsg = ""

    enum PurchaseResult {
        case success(app: AppMeta, alreadyOwned: Bool)
        case failure(message: String)
    }

    private var api: APIService { APIService(baseURL: appState.serverURL) }

    var body: some View {
        NavigationView {
            ScrollView {
                VStack(spacing: 20) {

                    // Info banner
                    HStack(spacing: 12) {
                        Image(systemName: "bag.circle.fill")
                            .font(.title2)
                            .foregroundColor(.purple)
                        VStack(alignment: .leading, spacing: 3) {
                            Text("Thêm vào Đã Mua")
                                .font(.system(size: 14, weight: .bold))
                                .foregroundColor(.primary)
                            Text("Thêm app miễn phí vào lịch sử, sau đó tải IPA")
                                .font(.caption)
                                .foregroundColor(.secondary)
                        }
                    }
                    .padding(16)
                    .frame(maxWidth: .infinity, alignment: .leading)
                    .background(Color.purple.opacity(0.1))
                    .clipShape(RoundedRectangle(cornerRadius: 14))
                    .overlay(RoundedRectangle(cornerRadius: 14).stroke(Color.purple.opacity(0.2), lineWidth: 1))
                    .padding(.horizontal, 16)
                    .padding(.top, 8)

                    // Input Card
                    VStack(spacing: 16) {
                        IPADLTextField(
                            icon: "app.badge.fill",
                            placeholder: "App ID hoặc link App Store",
                            text: $appInput
                        )

                        if !errorMsg.isEmpty {
                            HStack(spacing: 8) {
                                Image(systemName: "exclamationmark.triangle.fill").foregroundColor(.orange).font(.caption)
                                Text(errorMsg).font(.caption).foregroundColor(.orange)
                            }
                        }

                        Button {
                            Task { await performPurchase() }
                        } label: {
                            HStack(spacing: 10) {
                                if isLoading {
                                    ProgressView().tint(.white).scaleEffect(0.85)
                                } else {
                                    Image(systemName: "plus.circle.fill")
                                }
                                Text(isLoading ? "Đang xử lý..." : "Thêm vào Đã Mua")
                                    .font(.system(size: 16, weight: .bold))
                            }
                            .foregroundColor(.white)
                            .frame(maxWidth: .infinity)
                            .frame(height: 52)
                            .background(
                                LinearGradient(colors: isLoading ? [.gray] : [.purple, Color("AccentSecondary")],
                                               startPoint: .leading, endPoint: .trailing)
                            )
                            .clipShape(RoundedRectangle(cornerRadius: 14))
                            .shadow(color: isLoading ? .clear : Color.purple.opacity(0.3), radius: 10, y: 4)
                        }
                        .disabled(isLoading || appInput.trimmingCharacters(in: .whitespaces).isEmpty)
                    }
                    .padding(20)
                    .background(Color("Card"))
                    .clipShape(RoundedRectangle(cornerRadius: 20))
                    .padding(.horizontal, 16)

                    // Result
                    if let result = result {
                        purchaseResultView(result: result)
                            .padding(.horizontal, 16)
                            .transition(.move(edge: .bottom).combined(with: .opacity))
                    }

                    Spacer(minLength: 20)
                }
            }
            .background(Color("BG"))
            .navigationTitle("Đã Mua")
            .navigationBarTitleDisplayMode(.large)
        }
    }

    // MARK: - Result View

    @ViewBuilder
    func purchaseResultView(result: PurchaseResult) -> some View {
        switch result {
        case .success(let app, let alreadyOwned):
            VStack(spacing: 16) {
                HStack(spacing: 10) {
                    Image(systemName: alreadyOwned ? "info.circle.fill" : "checkmark.circle.fill")
                        .foregroundColor(alreadyOwned ? .orange : .green)
                        .font(.title2)
                    Text(alreadyOwned ? "Đã có sẵn!" : "Thêm thành công!")
                        .font(.headline)
                        .foregroundColor(.primary)
                }

                // App info row
                HStack(spacing: 14) {
                    AsyncImage(url: URL(string: app.icon ?? "")) { img in
                        img.resizable().scaledToFill()
                    } placeholder: {
                        RoundedRectangle(cornerRadius: 10).fill(Color("FieldBG"))
                            .overlay(Image(systemName: "app.fill").foregroundColor(.secondary))
                    }
                    .frame(width: 52, height: 52)
                    .clipShape(RoundedRectangle(cornerRadius: 12))

                    VStack(alignment: .leading, spacing: 4) {
                        Text(app.name ?? "Unknown").font(.system(size: 15, weight: .bold)).lineLimit(1).foregroundColor(.primary)
                        Text(app.artistName ?? "").font(.caption).foregroundColor(.secondary)
                        Text("v\(app.version ?? "")").font(.caption2).foregroundColor(Color("Accent"))
                    }
                    Spacer()
                }
                .padding(14)
                .background(Color("FieldBG"))
                .clipShape(RoundedRectangle(cornerRadius: 14))

                // Go to download
                Button {
                    let raw = appInput
                    let appId: String
                    if let match = raw.range(of: #"/id(\d+)"#, options: .regularExpression) {
                        appId = String(raw[match]).replacingOccurrences(of: "/id", with: "")
                    } else {
                        appId = raw
                    }
                    appState.resetDownload()
                    appState.activeTab = .download
                } label: {
                    HStack {
                        Image(systemName: "arrow.down.circle.fill")
                        Text("Tải IPA ngay").font(.system(size: 15, weight: .bold))
                    }
                    .foregroundColor(.white)
                    .frame(maxWidth: .infinity)
                    .frame(height: 48)
                    .background(LinearGradient(colors: [Color("Accent"), Color("AccentSecondary")], startPoint: .leading, endPoint: .trailing))
                    .clipShape(RoundedRectangle(cornerRadius: 14))
                }
            }
            .padding(20)
            .background(Color("Card"))
            .clipShape(RoundedRectangle(cornerRadius: 20))

        case .failure(let msg):
            HStack(spacing: 12) {
                Image(systemName: "xmark.circle.fill").foregroundColor(.red).font(.title3)
                Text(msg).font(.subheadline).foregroundColor(.primary)
            }
            .padding(16)
            .frame(maxWidth: .infinity, alignment: .leading)
            .background(Color.red.opacity(0.08))
            .clipShape(RoundedRectangle(cornerRadius: 14))
        }
    }

    // MARK: - Action

    func performPurchase() async {
        let raw = appInput.trimmingCharacters(in: .whitespaces)
        guard !raw.isEmpty else { return }

        isLoading = true
        errorMsg = ""
        result = nil

        guard let token = await api.getPurchaseToken() else {
            isLoading = false
            errorMsg = "Lỗi phiên. Vui lòng đăng nhập lại."
            return
        }

        let resp = await api.purchase(input: raw, recaptchaToken: "", purchaseToken: token)
        isLoading = false

        withAnimation(.spring(response: 0.4)) {
            if resp?.success == true {
                result = .success(app: resp?.app ?? AppMeta(name: nil, bundleId: nil, version: nil, artistName: nil, adamId: nil, icon: nil), alreadyOwned: resp?.alreadyInPurchased ?? false)
            } else if resp?.require2FA == true {
                appState.isLoggedIn = false
            } else {
                result = .failure(message: resp?.error ?? "Thất bại. Kiểm tra lại App ID.")
            }
        }
    }
}
