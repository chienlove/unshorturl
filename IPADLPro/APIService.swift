import Foundation

class APIService {
    let baseURL: String
    private let session: URLSession

    init(baseURL: String) {
        self.baseURL = baseURL.trimmingCharacters(in: .init(charactersIn: "/"))
        let config = URLSessionConfiguration.default
        config.httpCookieAcceptPolicy = .always
        config.httpShouldSetCookies = true
        config.httpCookieStorage = .shared
        config.timeoutIntervalForRequest = 30
        self.session = URLSession(configuration: config)
    }

    // MARK: - Session

    func checkSession() async -> SessionCheckResponse? {
        return await get("/session-check")
    }

    func logout() async {
        let _: AuthResponse? = await post("/logout", body: [:])
    }

    // MARK: - Auth

    func login(appleId: String, password: String, deviceId: String) async -> AuthResponse? {
        return await post("/login", body: [
            "appleId": appleId,
            "password": password,
            "clientDeviceId": deviceId
        ])
    }

    func verify2FA(appleId: String, code: String, deviceId: String) async -> AuthResponse? {
        return await post("/verify2fa", body: [
            "appleId": appleId,
            "mfaCode": code,
            "clientDeviceId": deviceId
        ])
    }

    // MARK: - Download

    func startDownload(appId: String, appVerId: String?, deviceId: String, purchaseToken: String) async -> DownloadStartResponse? {
        var body: [String: Any] = ["APPID": appId, "clientDeviceId": deviceId]
        if let v = appVerId, !v.isEmpty { body["appVerId"] = v }
        return await postWithToken("/download", body: body, token: purchaseToken)
    }

    func getProgress(requestId: String) async -> ProgressResponse? {
        return await get("/progress/\(requestId)")
    }

    // MARK: - Purchase

    func getPurchaseToken() async -> String? {
        let resp: PurchaseTokenResponse? = await post("/purchase-token", body: [:])
        return resp?.token
    }

    func purchase(input: String, recaptchaToken: String, purchaseToken: String) async -> PurchaseResponse? {
        return await postWithToken("/purchase", body: [
            "input": input,
            "recaptchaToken": recaptchaToken
        ], token: purchaseToken)
    }

    // MARK: - Generic Helpers

    private func get<T: Decodable>(_ path: String) async -> T? {
        guard let url = URL(string: baseURL + path) else { return nil }
        var req = URLRequest(url: url)
        req.httpMethod = "GET"
        req.setValue("application/json", forHTTPHeaderField: "Accept")
        do {
            let (data, _) = try await session.data(for: req)
            return try JSONDecoder().decode(T.self, from: data)
        } catch { return nil }
    }

    private func post<T: Decodable>(_ path: String, body: [String: Any]) async -> T? {
        guard let url = URL(string: baseURL + path) else { return nil }
        var req = URLRequest(url: url)
        req.httpMethod = "POST"
        req.setValue("application/json", forHTTPHeaderField: "Content-Type")
        req.httpBody = try? JSONSerialization.data(withJSONObject: body)
        do {
            let (data, _) = try await session.data(for: req)
            return try JSONDecoder().decode(T.self, from: data)
        } catch { return nil }
    }

    private func postWithToken<T: Decodable>(_ path: String, body: [String: Any], token: String) async -> T? {
        guard let url = URL(string: baseURL + path) else { return nil }
        var req = URLRequest(url: url)
        req.httpMethod = "POST"
        req.setValue("application/json", forHTTPHeaderField: "Content-Type")
        req.setValue(token, forHTTPHeaderField: "x-purchase-token")
        req.httpBody = try? JSONSerialization.data(withJSONObject: body)
        do {
            let (data, _) = try await session.data(for: req)
            return try JSONDecoder().decode(T.self, from: data)
        } catch { return nil }
    }
}
