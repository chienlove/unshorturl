import SwiftUI

struct LoginView: View {
    @EnvironmentObject var appState: AppState
    @State private var appleId = ""
    @State private var password = ""
    @State private var mfaCode = ""
    @State private var isLoading = false
    @State private var needs2FA = false
    @State private var errorMessage = ""
    @State private var appear = false

    private var api: APIService { APIService(baseURL: appState.serverURL) }

    var body: some View {
        ScrollView {
            VStack(spacing: 0) {
                // Logo Section
                VStack(spacing: 16) {
                    ZStack {
                        Circle()
                            .fill(LinearGradient(colors: [Color("Accent"), Color("AccentSecondary")], startPoint: .topLeading, endPoint: .bottomTrailing))
                            .frame(width: 90, height: 90)
                            .shadow(color: Color("Accent").opacity(0.5), radius: 24, y: 8)
                        Image(systemName: "arrow.down.circle.fill")
                            .font(.system(size: 44, weight: .bold))
                            .foregroundColor(.white)
                    }
                    .scaleEffect(appear ? 1 : 0.6)
                    .opacity(appear ? 1 : 0)

                    VStack(spacing: 6) {
                        Text("IPADL Pro")
                            .font(.system(size: 34, weight: .black, design: .rounded))
                            .foregroundStyle(LinearGradient(colors: [Color("Accent"), Color("AccentSecondary")], startPoint: .leading, endPoint: .trailing))
                        Text("Tải IPA từ App Store dễ dàng")
                            .font(.subheadline)
                            .foregroundColor(.secondary)
                    }
                    .offset(y: appear ? 0 : 20)
                    .opacity(appear ? 1 : 0)
                }
                .padding(.top, 60)
                .padding(.bottom, 40)

                // Form Card
                VStack(spacing: 20) {
                    if !needs2FA {
                        // Apple ID + Password fields
                        VStack(spacing: 14) {
                            IPADLTextField(
                                icon: "envelope.fill",
                                placeholder: "Apple ID (email)",
                                text: $appleId,
                                keyboardType: .emailAddress
                            )
                            IPADLSecureField(
                                icon: "lock.fill",
                                placeholder: "Mật khẩu",
                                text: $password
                            )
                        }
                    } else {
                        // 2FA field
                        VStack(spacing: 12) {
                            HStack(spacing: 10) {
                                Image(systemName: "shield.fill")
                                    .foregroundColor(Color("Accent"))
                                Text("Nhập mã xác minh 2 bước")
                                    .font(.headline)
                                    .foregroundColor(.primary)
                            }
                            Text("Apple đã gửi mã 6 chữ số đến thiết bị của bạn")
                                .font(.caption)
                                .foregroundColor(.secondary)
                                .multilineTextAlignment(.center)

                            IPADLTextField(
                                icon: "key.fill",
                                placeholder: "Mã 2FA (6 chữ số)",
                                text: $mfaCode,
                                keyboardType: .numberPad
                            )
                        }
                    }

                    // Error Message
                    if !errorMessage.isEmpty {
                        HStack(spacing: 8) {
                            Image(systemName: "exclamationmark.triangle.fill")
                                .foregroundColor(.red)
                                .font(.caption)
                            Text(errorMessage)
                                .font(.caption)
                                .foregroundColor(.red)
                        }
                        .padding(12)
                        .frame(maxWidth: .infinity)
                        .background(Color.red.opacity(0.1))
                        .clipShape(RoundedRectangle(cornerRadius: 10))
                    }

                    // Action Button
                    Button {
                        Task { await performAction() }
                    } label: {
                        HStack(spacing: 10) {
                            if isLoading {
                                ProgressView()
                                    .tint(.white)
                                    .scaleEffect(0.9)
                            }
                            Text(needs2FA ? "Xác nhận 2FA" : "Đăng nhập")
                                .font(.system(size: 17, weight: .bold))
                        }
                        .foregroundColor(.white)
                        .frame(maxWidth: .infinity)
                        .frame(height: 54)
                        .background(
                            LinearGradient(colors: [Color("Accent"), Color("AccentSecondary")], startPoint: .leading, endPoint: .trailing)
                        )
                        .clipShape(RoundedRectangle(cornerRadius: 16))
                        .shadow(color: Color("Accent").opacity(0.4), radius: 12, y: 6)
                    }
                    .disabled(isLoading || (needs2FA ? mfaCode.isEmpty : (appleId.isEmpty || password.isEmpty)))
                    .opacity(isLoading ? 0.8 : 1)

                    if needs2FA {
                        Button("Quay lại") {
                            withAnimation { needs2FA = false; errorMessage = ""; mfaCode = "" }
                        }
                        .font(.subheadline)
                        .foregroundColor(.secondary)
                    }
                }
                .padding(24)
                .background(Color("Card"))
                .clipShape(RoundedRectangle(cornerRadius: 24))
                .padding(.horizontal, 16)
                .offset(y: appear ? 0 : 30)
                .opacity(appear ? 1 : 0)

                // Footer
                Text("Thông tin đăng nhập chỉ dùng để xác thực với Apple.\nKhông được lưu trữ trên server.")
                    .font(.caption2)
                    .foregroundColor(.secondary)
                    .multilineTextAlignment(.center)
                    .padding(.top, 24)
                    .padding(.horizontal, 32)
                    .opacity(appear ? 1 : 0)

                Spacer(minLength: 40)
            }
        }
        .background(Color("BG").ignoresSafeArea())
        .onAppear {
            withAnimation(.spring(response: 0.7, dampingFraction: 0.8)) { appear = true }
        }
    }

    // MARK: - Actions

    func performAction() async {
        isLoading = true
        errorMessage = ""

        if needs2FA {
            let resp = await api.verify2FA(appleId: appleId, code: mfaCode, deviceId: appState.deviceId)
            await MainActor.run {
                isLoading = false
                if resp?.success == true {
                    appState.isLoggedIn = true
                    appState.appleIdMasked = resp?.message ?? appleId
                } else {
                    errorMessage = resp?.error ?? "Mã 2FA không đúng. Thử lại."
                }
            }
        } else {
            let resp = await api.login(appleId: appleId, password: password, deviceId: appState.deviceId)
            await MainActor.run {
                isLoading = false
                if resp?.success == true {
                    appState.isLoggedIn = true
                    appState.appleIdMasked = appleId
                } else if resp?.require2FA == true {
                    withAnimation { needs2FA = true }
                } else {
                    errorMessage = resp?.error ?? "Đăng nhập thất bại. Kiểm tra lại thông tin."
                }
            }
        }
    }
}

// MARK: - Custom Text Fields

struct IPADLTextField: View {
    let icon: String
    let placeholder: String
    @Binding var text: String
    var keyboardType: UIKeyboardType = .default

    var body: some View {
        HStack(spacing: 12) {
            Image(systemName: icon)
                .foregroundColor(Color("Accent"))
                .frame(width: 20)
            TextField(placeholder, text: $text)
                .keyboardType(keyboardType)
                .autocapitalization(.none)
                .autocorrectionDisabled()
                .foregroundColor(.primary)
        }
        .padding(16)
        .background(Color("FieldBG"))
        .clipShape(RoundedRectangle(cornerRadius: 14))
        .overlay(RoundedRectangle(cornerRadius: 14).stroke(Color.white.opacity(0.06), lineWidth: 1))
    }
}

struct IPADLSecureField: View {
    let icon: String
    let placeholder: String
    @Binding var text: String
    @State private var showPassword = false

    var body: some View {
        HStack(spacing: 12) {
            Image(systemName: icon)
                .foregroundColor(Color("Accent"))
                .frame(width: 20)
            Group {
                if showPassword {
                    TextField(placeholder, text: $text).autocapitalization(.none).autocorrectionDisabled()
                } else {
                    SecureField(placeholder, text: $text)
                }
            }
            .foregroundColor(.primary)
            Button { showPassword.toggle() } label: {
                Image(systemName: showPassword ? "eye.slash.fill" : "eye.fill")
                    .foregroundColor(.secondary)
                    .font(.caption)
            }
        }
        .padding(16)
        .background(Color("FieldBG"))
        .clipShape(RoundedRectangle(cornerRadius: 14))
        .overlay(RoundedRectangle(cornerRadius: 14).stroke(Color.white.opacity(0.06), lineWidth: 1))
    }
}
