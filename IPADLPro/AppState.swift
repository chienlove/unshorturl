import SwiftUI
import Combine

class AppState: ObservableObject {
    // MARK: - Auth State
    @Published var isLoggedIn: Bool = false
    @Published var appleIdMasked: String = ""
    @Published var isCheckingSession: Bool = true

    // MARK: - Download State
    @Published var downloadStatus: DownloadStatus = .idle
    @Published var progressSteps: [ProgressStep] = []
    @Published var requestId: String? = nil
    @Published var currentProgress: Double = 0

    // MARK: - UI State
    @Published var activeTab: Tab = .home
    @Published var showLoginSheet: Bool = false

    // MARK: - Device ID
    let deviceId: String = {
        if let saved = UserDefaults.standard.string(forKey: "IPADL_DEVICE_ID") {
            return saved
        }
        let new = UUID().uuidString
        UserDefaults.standard.set(new, forKey: "IPADL_DEVICE_ID")
        return new
    }()

    // MARK: - Server URL
    var serverURL: String {
        get { UserDefaults.standard.string(forKey: "SERVER_URL") ?? "https://ipadl.storeios.net" }
        set { UserDefaults.standard.set(newValue, forKey: "SERVER_URL") }
    }

    private var progressTimer: Timer?
    private var api: APIService { APIService(baseURL: serverURL) }

    func checkSession() {
        isCheckingSession = true
        Task { @MainActor in
            let result = await api.checkSession()
            self.isLoggedIn = result?.isLoggedIn ?? false
            self.appleIdMasked = result?.appleIdMasked ?? ""
            self.isCheckingSession = false
        }
    }

    func logout() {
        Task { @MainActor in
            await api.logout()
            self.isLoggedIn = false
            self.appleIdMasked = ""
            self.downloadStatus = .idle
            self.progressSteps = []
        }
    }

    func startPolling(requestId: String) {
        self.requestId = requestId
        stopPolling()
        progressTimer = Timer.scheduledTimer(withTimeInterval: 1.5, repeats: true) { [weak self] _ in
            Task { @MainActor [weak self] in
                await self?.pollProgress(requestId: requestId)
            }
        }
    }

    func stopPolling() {
        progressTimer?.invalidate()
        progressTimer = nil
    }

    @MainActor
    private func pollProgress(requestId: String) async {
        guard let resp = await api.getProgress(requestId: requestId) else { return }

        let status = resp.status ?? "pending"
        let progress = resp.progress ?? 0
        let message = resp.message ?? "Đang xử lý..."
        let detail = resp.detail ?? ""

        let step = ProgressStep(message: message, detail: detail, progress: progress, timestamp: Date())
        if progressSteps.last?.message != message {
            progressSteps.append(step)
        }
        currentProgress = progress

        switch status {
        case "done":
            stopPolling()
            if let url = resp.downloadUrl {
                downloadStatus = .done(
                    info: resp.appInfo ?? AppInfo(name: nil, version: nil, size: nil, minOS: nil, icon: nil, artistName: nil, bundleId: nil, adamId: nil),
                    downloadUrl: url,
                    otaUrl: resp.otaUrl
                )
            }
        case "error":
            stopPolling()
            downloadStatus = .error(message: resp.error ?? "Đã xảy ra lỗi")
        default:
            downloadStatus = .downloading(progress: progress, message: message, detail: detail)
        }
    }

    func resetDownload() {
        stopPolling()
        downloadStatus = .idle
        progressSteps = []
        currentProgress = 0
        requestId = nil
    }
}
