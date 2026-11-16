import SwiftUI
import Lottie

struct LottieView: UIViewRepresentable {
    let name: String
    @Environment(\.accessibilityReduceMotion) private var reduceMotion

    func makeUIView(context: Context) -> LottieAnimationView {
        let view = LottieAnimationView(name: name)
        view.loopMode = .loop
        view.contentMode = .scaleAspectFit
        return view
    }

    func updateUIView(_ uiView: LottieAnimationView, context: Context) {
        if reduceMotion {
            uiView.stop()
            uiView.currentProgress = 0.5
        } else if !uiView.isAnimationPlaying {
            uiView.play()
        }
    }

    static func dismantleUIView(_ uiView: LottieAnimationView, coordinator: ()) { uiView.stop() }
}
