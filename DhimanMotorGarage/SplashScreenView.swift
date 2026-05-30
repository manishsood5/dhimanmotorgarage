import SwiftUI

struct SplashScreenView: View {
    var body: some View {
        ZStack {
            Color.white
                .ignoresSafeArea()

            VStack(spacing: 0) {
                Spacer()

                Image("SplashLogo")
                    .resizable()
                    .scaledToFit()
                    .frame(maxWidth: 320)
                    .padding(.horizontal, 24)

                Spacer()
                    .frame(height: 40)

                Text("Dhiman Motor Garage")
                    .font(.system(size: 26, weight: .bold))
                    .foregroundColor(Color(red: 0.30, green: 0.30, blue: 0.30))
                    .multilineTextAlignment(.center)

                Spacer()
                    .frame(height: 12)

                Text("Founder: Ram Ishwar Singh")
                    .font(.system(size: 16, weight: .regular))
                    .foregroundColor(Color(red: 0.50, green: 0.50, blue: 0.50))
                    .multilineTextAlignment(.center)

                Spacer()
            }
            .padding(.horizontal, 32)
        }
        .frame(maxWidth: .infinity, maxHeight: .infinity)
    }
}

struct SplashScreenView_Previews: PreviewProvider {
    static var previews: some View {
        SplashScreenView()
    }
}
