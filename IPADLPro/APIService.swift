import Foundation

class APIService {
    let baseURL: String
    private let session: URLSession

    init(baseURL: String) {
        // Đảm bảo URL không có gạch chéo thừa ở cuối
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
        // Endpoint khớp với app.post('/auth') trong server.js
        return await post("/auth", body: [
            "APPLE_ID": appleId,       // Key viết hoa theo server.js
            "PASSWORD": password,      // Key viết hoa theo server.js
            "clientDeviceId": deviceId
        ])
    }

    func verify2FA(appleId: String, code: String, deviceId: String) async -> AuthResponse? {
        // Endpoint khớp với app.post('/verify') trong server.js
        return await post("/verify", body: [
            "APPLE_ID": appleId,
            "CODE": code,              // Đổi mfaCode thành CODE theo server.js
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

    // MARK: - Generic Helpers (With Debugging)

    private func get<T: Decodable>(_ path: String) async -> T? {
        guard let url = URL(string: baseURL + path) else { return nil }
        var req = URLRequest(url: url)
        req.httpMethod = "GET"
        req.setValue("application/json", forHTTPHeaderField: "Accept")
        
        // Giả lập trình duyệt
        req.setValue("Mozilla/5.0 (iPhone; CPU iPhone OS 17_0 like Mac OS X) AppleWebKit/605.1.15 (KHTML, like Gecko) Version/17.0 Mobile/15E148 Safari/604.1", forHTTPHeaderField: "User-Agent")
        
        do {
            let (data, _) = try await session.data(for: req)
            return try JSONDecoder().decode(T.self, from: data)
        } catch {
            print("❌ Lỗi GET \(path): \(error)")
            return nil
        }
    }

    private func post<T: Decodable>(_ path: String, body: [String: Any]) async -> T? {
        guard let url = URL(string: baseURL + path) else { return nil }
        var req = URLRequest(url: url)
        req.httpMethod = "POST"
        req.setValue("application/json", forHTTPHeaderField: "Content-Type")
        
        // Giả lập trình duyệt
        req.setValue("Mozilla/5.0 (iPhone; CPU iPhone OS 17_0 like Mac OS X) AppleWebKit/605.1.15 (KHTML, like Gecko) Version/17.0 Mobile/15E148 Safari/604.1", forHTTPHeaderField: "User-Agent")
        
        req.httpBody = try? JSONSerialization.data(withJSONObject: body)
        
        do {
            let (data, response) = try await session.data(for: req)
            
            // Debug Status Code
            let statusCode = (response as? HTTPURLResponse)?.statusCode ?? 0
            if statusCode != 200 {
                print("⚠️ POST \(path) trả về Status: \(statusCode)")
            }

            do {
                return try JSONDecoder().decode(T.self, from: data)
            } catch {
                // Nếu là AuthResponse, thử trả về lỗi chi tiết để hiện lên UI
                if T.self == AuthResponse.self {
                    let rawData = String(data: data, encoding: .utf8) ?? "Dữ liệu trống"
                    print("❌ Lỗi Decode JSON tại \(path). Server trả về: \(rawData)")
                    
                    // Trả về một AuthResponse giả chứa thông báo lỗi thô từ server để dễ debug
                    return AuthResponse(success: false, require2FA: false, error: "Lỗi đọc dữ liệu: \(rawData.prefix(50))...", message: nil, sessionId: nil) as? T
                }
                return nil
            }
        } catch {
            print("❌ Lỗi kết nối POST \(path): \(error)")
            return nil
        }
    }

    private func postWithToken<T: Decodable>(_ path: String, body: [String: Any], token: String) async -> T? {
        guard let url = URL(string: baseURL + path) else { return nil }
        var req = URLRequest(url: url)
        req.httpMethod = "POST"
        req.setValue("application/json", forHTTPHeaderField: "Content-Type")
        req.setValue(token, forHTTPHeaderField: "x-purchase-token")
        
        // Giả lập trình duyệt
        req.setValue("Mozilla/5.0 (iPhone; CPU iPhone OS 17_0 like Mac OS X) AppleWebKit/605.1.15 (KHTML, like Gecko) Version/17.0 Mobile/15E148 Safari/604.1", forHTTPHeaderField: "User-Agent")
        
        req.httpBody = try? JSONSerialization.data(withJSONObject: body)
        
        do {
            let (data, _) = try await session.data(for: req)
            return try JSONDecoder().decode(T.self, from: data)
        } catch {
            print("❌ Lỗi POST with Token \(path): \(error)")
            return nil
        }
    }
}
