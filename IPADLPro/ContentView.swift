import SwiftUI

struct ContentView: View {
    @EnvironmentObject var appState: AppState

    var body: some View {
        ZStack {
            Color("BG").ignoresSafeArea()

            if appState.isCheckingSession {
                SplashView()
            } else if !appState.isLoggedIn {
                LoginView()
            } else {
                MainTabView()
            }
        }
        .onAppear { appState.checkSession() }
    }
}

// MARK: - Splash

struct SplashView: View {
    @State private var scale: CGFloat = 0.8
    @State private var opacity: Double = 0

    var body: some View {
        VStack(spacing: 20) {
            ZStack {
                Circle()
                    .fill(LinearGradient(colors: [Color("Accent"), Color("AccentSecondary")], startPoint: .topLeading, endPoint: .bottomTrailing))
                    .frame(width: 100, height: 100)
                    .shadow(color: Color("Accent").opacity(0.5), radius: 20)
                Image(systemName: "arrow.down.circle.fill")
                    .font(.system(size: 48, weight: .bold))
                    .foregroundColor(.white)
            }
            .scaleEffect(scale)
            .opacity(opacity)

            Text("IPADL Pro")
                .font(.system(size: 32, weight: .black, design: .rounded))
                .foregroundStyle(LinearGradient(colors: [Color("Accent"), Color("AccentSecondary")], startPoint: .leading, endPoint: .trailing))
                .opacity(opacity)
        }
        .onAppear {
            withAnimation(.spring(response: 0.6, dampingFraction: 0.7)) {
                scale = 1.0
                opacity = 1.0
            }
        }
    }
}

// MARK: - Main Tab View

struct MainTabView: View {
    @EnvironmentObject var appState: AppState

    var body: some View {
        TabView(selection: $appState.activeTab) {
            HomeView()
                .tabItem {
                    Label("Trang chủ", systemImage: "house.fill")
                }
                .tag(Tab.home)

            DownloadView()
                .tabItem {
                    Label("Tải xuống", systemImage: "arrow.down.circle.fill")
                }
                .tag(Tab.download)

            PurchaseView()
                .tabItem {
                    Label("Đã mua", systemImage: "bag.fill")
                }
                .tag(Tab.purchase)

            SettingsView()
                .tabItem {
                    Label("Cài đặt", systemImage: "gearshape.fill")
                }
                .tag(Tab.settings)
        }
        .tint(Color("Accent"))
    }
}
