import SwiftUI

struct SplashScreenView: View {
    @Binding var isActive: Bool
    @StateObject private var viewModel: SplashScreenViewModel

    init(viewModel: SplashScreenViewModel, isActive: Binding<Bool>) {
        _viewModel = StateObject(wrappedValue: viewModel)
        _isActive = isActive
    }

    var body: some View {
        VStack(spacing: 24) {
            Image("app_logo_image").resizable().scaledToFit().frame(maxWidth: 250).accessibilityHidden(true)
            LottieView(name: "Animation").frame(width: 100, height: 100).accessibilityHidden(true)
            Text("Preparando transportes…").font(.headline)
        }
        .padding()
        .task {
            async let bus: Void = viewModel.getBusStops()
            async let tram: Void = viewModel.getTramStops()
            _ = await (bus, tram)
            guard !Task.isCancelled else { return }
            isActive = false
        }
    }
}
