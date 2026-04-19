# IPADL Pro — iOS App

App iOS native để tải IPA từ App Store thông qua server IPADL Pro.

## Tính năng

- 🔐 Đăng nhập Apple ID + xác minh 2FA
- 📥 Tải IPA theo App ID hoặc link App Store
- 📊 Theo dõi tiến trình real-time
- 🛍️ Thêm app vào "Đã Mua"
- ⚙️ Tùy chỉnh URL server
- 🌙 Dark mode đẹp, animation mượt

## Yêu cầu

- iOS 16.0+
- Xcode 15+

## Build bằng GitHub Actions

1. Push code lên GitHub
2. Vào tab **Actions** → chọn **Build IPA (Unsigned)**
3. Chờ build xong (~5-10 phút)
4. Tải file IPA từ tab **Artifacts**
5. Sign IPA bằng cert của bạn rồi cài đặt

## Cấu hình server

Mở app → tab **Cài đặt** → nhập URL server của bạn.

Mặc định: `https://ipadl.storeios.net`

## Cấu trúc project

```
IPADLPro/
├── IPADLProApp.swift      # App entry point
├── ContentView.swift      # Root navigation + splash
├── HomeView.swift         # Dashboard chính
├── LoginView.swift        # Đăng nhập + 2FA
├── DownloadView.swift     # Tải IPA
├── ProgressView.swift     # Tiến trình real-time
├── PurchaseView.swift     # Thêm vào Đã Mua
├── SettingsView.swift     # Cài đặt
├── APIService.swift       # Network layer
├── AppState.swift         # Global state (ObservableObject)
├── Models.swift           # Data models
└── Assets.xcassets/       # Colors, icons
```
