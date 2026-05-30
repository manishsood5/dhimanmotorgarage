import SwiftUI

struct ContentView: View {
    private let homeURL = URL(string: "https://dhimanmotorgarage.in/myapp/mobile-service-app/")!

    @State private var isLoading = true
    @State private var progress: Double = 0

    var body: some View {
        ZStack {
            Color.white
                .ignoresSafeArea()

            WebView(url: homeURL, isLoading: $isLoading, progress: $progress)

            if isLoading {
                ZStack {
                    Color.black.opacity(0.25)
                        .ignoresSafeArea()

                    ProgressView()
                        .progressViewStyle(CircularProgressViewStyle(tint: Color(red: 0.95, green: 0.60, blue: 0.05)))
                        .scaleEffect(1.6)
                        .padding(28)
                        .background(
                            RoundedRectangle(cornerRadius: 16)
                                .fill(Color.black.opacity(0.55))
                        )
                }
                .transition(.opacity)
            }
        }
        .animation(.easeInOut(duration: 0.25), value: isLoading)
    }
}

struct ContentView_Previews: PreviewProvider {
    static var previews: some View {
        ContentView()
    }
}
