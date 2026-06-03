import SwiftUI

struct ContentView: View {
    private let homeURL = URL(string: "https://dhimanmotorgarage.in/myapp/mobile-service-app/")!
    private let amber = Color(red: 0.95, green: 0.60, blue: 0.05)

    @StateObject private var network = NetworkMonitor()

    @State private var isLoading = true
    @State private var progress: Double = 0
    @State private var navigateTo: URL?

    var body: some View {
        ZStack {
            Color.white
                .ignoresSafeArea()

            WebView(
                url: homeURL,
                isLoading: $isLoading,
                progress: $progress,
                navigateTo: $navigateTo
            )

            if isLoading && network.isConnected {
                ZStack {
                    Color.black.opacity(0.25)
                        .ignoresSafeArea()

                    ProgressView()
                        .progressViewStyle(CircularProgressViewStyle(tint: amber))
                        .scaleEffect(1.6)
                        .padding(28)
                        .background(
                            RoundedRectangle(cornerRadius: 16)
                                .fill(Color.black.opacity(0.55))
                        )
                }
                .transition(.opacity)
            }

            if !network.isConnected {
                NoInternetView(amber: amber) {
                    navigateTo = homeURL
                }
                .transition(.opacity)
            }
        }
        .animation(.easeInOut(duration: 0.3), value: isLoading)
        .animation(.easeInOut(duration: 0.35), value: network.isConnected)
        .onChange(of: network.isConnected) { isConnected in
            if isConnected { navigateTo = homeURL }
        }
    }
}

// MARK: - No Internet View

private struct NoInternetView: View {
    let amber: Color
    let onRetry: () -> Void

    var body: some View {
        ZStack {
            Color.white.ignoresSafeArea()

            VStack(spacing: 0) {
                Spacer()

                Image(systemName: "wifi.slash")
                    .font(.system(size: 64, weight: .light))
                    .foregroundColor(amber)
                    .padding(.bottom, 28)

                Text("No Internet Connection")
                    .font(.system(size: 22, weight: .semibold))
                    .foregroundColor(Color(red: 0.15, green: 0.15, blue: 0.15))
                    .multilineTextAlignment(.center)
                    .padding(.bottom, 12)

                Text("Please check your Wi-Fi or mobile data\nand try again.")
                    .font(.system(size: 15, weight: .regular))
                    .foregroundColor(Color(red: 0.45, green: 0.45, blue: 0.45))
                    .multilineTextAlignment(.center)
                    .lineSpacing(4)
                    .padding(.bottom, 40)

                Button(action: onRetry) {
                    HStack(spacing: 8) {
                        Image(systemName: "arrow.clockwise")
                            .font(.system(size: 15, weight: .semibold))
                        Text("Try Again")
                            .font(.system(size: 16, weight: .semibold))
                    }
                    .foregroundColor(.white)
                    .padding(.horizontal, 36)
                    .padding(.vertical, 14)
                    .background(amber)
                    .clipShape(Capsule())
                }

                Spacer()
            }
            .padding(.horizontal, 32)
        }
    }
}

struct ContentView_Previews: PreviewProvider {
    static var previews: some View {
        ContentView()
    }
}
