import SwiftUI

struct HomeView: View {
    @EnvironmentObject var appState: AppState
    @State private var appear = false

    var body: some View {
        NavigationView {
            ScrollView {
                VStack(spacing: 24) {
                    // Header Card
                    headerCard
                        .offset(y: appear ? 0 : 30)
                        .opacity(appear ? 1 : 0)

                    // Feature Cards
                    LazyVGrid(columns: [GridItem(.flexible()), GridItem(.flexible())], spacing: 16) {
                        FeatureCard(icon: "arrow.down.circle.fill", title: "Tải IPA", subtitle: "Download bất kỳ app nào", color: Color("Accent")) {
                            appState.activeTab = .download
                        }
                        .offset(y: appear ? 0 : 40)
                        .opacity(appear ? 1 : 0)
                        .animation(.spring(response: 0.5).delay(0.1), value: appear)

                        FeatureCard(icon: "bag.fill", title: "Thêm Đã Mua", subtitle: "Mua app miễn phí", color: .purple) {
                            appState.activeTab = .purchase
                        }
                        .offset(y: appear ? 0 : 40)
                        .opacity(appear ? 1 : 0)
                        .animation(.spring(response: 0.5).delay(0.15), value: appear)

                        FeatureCard(icon: "clock.fill", title: "Lịch sử", subtitle: "Các lần tải gần đây", color: .orange) {}
                        .offset(y: appear ? 0 : 40)
                        .opacity(appear ? 1 : 0)
                        .animation(.spring(response: 0.5).delay(0.2), value: appear)

                        FeatureCard(icon: "gearshape.fill", title: "Cài đặt", subtitle: "Server & tùy chỉnh", color: .green) {
                            appState.activeTab = .settings
                        }
                        .offset(y: appear ? 0 : 40)
                        .opacity(appear ? 1 : 0)
                        .animation(.spring(response: 0.5).delay(0.25), value: appear)
                    }
                    .padding(.horizontal, 16)

                    // Info Banner
                    infoBanner
                        .offset(y: appear ? 0 : 20)
                        .opacity(appear ? 1 : 0)
                        .animation(.spring(response: 0.5).delay(0.3), value: appear)

                    Spacer(minLength: 20)
                }
                .padding(.top, 8)
            }
            .background(Color("BG"))
            .navigationTitle("IPADL Pro")
            .navigationBarTitleDisplayMode(.large)
        }
        .onAppear {
            withAnimation(.spring(response: 0.6)) { appear = true }
        }
    }

    // MARK: - Header Card

    var headerCard: some View {
        HStack(spacing: 16) {
            ZStack {
                Circle()
                    .fill(LinearGradient(colors: [Color("Accent"), Color("AccentSecondary")], startPoint: .topLeading, endPoint: .bottomTrailing))
                    .frame(width: 56, height: 56)
                    .shadow(color: Color("Accent").opacity(0.4), radius: 12, y: 6)
                Image(systemName: "person.fill")
                    .foregroundColor(.white)
                    .font(.title2)
            }

            VStack(alignment: .leading, spacing: 4) {
                Text("Xin chào!")
                    .font(.caption)
                    .foregroundColor(.secondary)
                Text(appState.appleIdMasked.isEmpty ? "Apple Account" : appState.appleIdMasked)
                    .font(.system(size: 16, weight: .semibold, design: .rounded))
                    .foregroundColor(.primary)
                    .lineLimit(1)
            }

            Spacer()

            // Status pill
            HStack(spacing: 6) {
                Circle()
                    .fill(.green)
                    .frame(width: 8, height: 8)
                Text("Online")
                    .font(.caption2.weight(.semibold))
                    .foregroundColor(.green)
            }
            .padding(.horizontal, 10)
            .padding(.vertical, 5)
            .background(Color.green.opacity(0.12))
            .clipShape(Capsule())
        }
        .padding(20)
        .background(Color("Card"))
        .clipShape(RoundedRectangle(cornerRadius: 20))
        .padding(.horizontal, 16)
    }

    // MARK: - Info Banner

    var infoBanner: some View {
        HStack(spacing: 14) {
            Image(systemName: "info.circle.fill")
                .foregroundColor(Color("Accent"))
                .font(.title3)

            VStack(alignment: .leading, spacing: 3) {
                Text("Cách sử dụng")
                    .font(.system(size: 14, weight: .semibold))
                    .foregroundColor(.primary)
                Text("Nhập App ID hoặc link App Store → Tải xuống → Nhận file IPA")
                    .font(.caption)
                    .foregroundColor(.secondary)
            }
        }
        .padding(16)
        .background(Color("Accent").opacity(0.08))
        .clipShape(RoundedRectangle(cornerRadius: 14))
        .overlay(RoundedRectangle(cornerRadius: 14).stroke(Color("Accent").opacity(0.2), lineWidth: 1))
        .padding(.horizontal, 16)
    }
}

// MARK: - Feature Card

struct FeatureCard: View {
    let icon: String
    let title: String
    let subtitle: String
    let color: Color
    let action: () -> Void

    @State private var pressed = false

    var body: some View {
        Button(action: action) {
            VStack(alignment: .leading, spacing: 12) {
                ZStack {
                    Circle()
                        .fill(color.opacity(0.15))
                        .frame(width: 48, height: 48)
                    Image(systemName: icon)
                        .foregroundColor(color)
                        .font(.title3.weight(.semibold))
                }

                VStack(alignment: .leading, spacing: 4) {
                    Text(title)
                        .font(.system(size: 15, weight: .bold, design: .rounded))
                        .foregroundColor(.primary)
                    Text(subtitle)
                        .font(.caption)
                        .foregroundColor(.secondary)
                        .lineLimit(2)
                }
            }
            .frame(maxWidth: .infinity, alignment: .leading)
            .padding(16)
            .background(Color("Card"))
            .clipShape(RoundedRectangle(cornerRadius: 18))
            .scaleEffect(pressed ? 0.96 : 1.0)
        }
        .buttonStyle(PlainButtonStyle())
        .simultaneousGesture(
            DragGesture(minimumDistance: 0)
                .onChanged { _ in withAnimation(.easeOut(duration: 0.1)) { pressed = true } }
                .onEnded { _ in withAnimation(.spring()) { pressed = false } }
        )
    }
}
