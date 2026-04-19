import Foundation

// MARK: - API Response Models

struct SessionCheckResponse: Codable {
    let isLoggedIn: Bool
    let appleIdMasked: String?
}

struct AuthResponse: Codable {
    let success: Bool
    let require2FA: Bool?
    let error: String?
    let message: String?
    let sessionId: String?
}

struct DownloadStartResponse: Codable {
    let success: Bool
    let requestId: String?
    let error: String?
    let message: String?
    let require2FA: Bool?
}

struct ProgressResponse: Codable {
    let progress: Double?
    let status: String?
    let message: String?
    let detail: String?
    let error: String?
    let downloadUrl: String?
    let otaUrl: String?
    let appInfo: AppInfo?
}

struct AppInfo: Codable, Equatable {
    let name: String?
    let version: String?
    let size: String?
    let minOS: String?
    let icon: String?
    let artistName: String?
    let bundleId: String?
    let adamId: String?
}

struct PurchaseResponse: Codable {
    let success: Bool
    let error: String?
    let message: String?
    let require2FA: Bool?
    let alreadyInPurchased: Bool?
    let app: AppMeta?
}

struct AppMeta: Codable {
    let name: String?
    let bundleId: String?
    let version: String?
    let artistName: String?
    let adamId: String?
    let icon: String?
}

struct PurchaseTokenResponse: Codable {
    let success: Bool
    let token: String?
}

// MARK: - UI State Models

enum DownloadStatus: Equatable {
    case idle
    case pending
    case downloading(progress: Double, message: String, detail: String)
    case done(info: AppInfo, downloadUrl: String, otaUrl: String?)
    case error(message: String)
}

enum Tab {
    case home, download, purchase, settings
}

struct ProgressStep: Identifiable {
    let id = UUID()
    let message: String
    let detail: String
    let progress: Double
    let timestamp: Date
}
