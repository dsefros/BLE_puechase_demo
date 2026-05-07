import Lottie
import SwiftUI
import UIKit

enum LottiePlaybackLoopMode {
    case loop
    case playOnce

    var lottieLoopMode: LottieLoopMode {
        switch self {
        case .loop:
            return .loop
        case .playOnce:
            return .playOnce
        }
    }
}

enum LottieContentMode {
    case aspectFit
    case aspectFill

    var uiViewContentMode: UIView.ContentMode {
        switch self {
        case .aspectFit:
            return .scaleAspectFit
        case .aspectFill:
            return .scaleAspectFill
        }
    }
}

struct LottieView<Fallback: View>: View {
    let animationName: String
    let loopMode: LottiePlaybackLoopMode
    let contentMode: LottieContentMode
    let autoplay: Bool
    let playbackSpeed: CGFloat
    let fallback: Fallback

    init(
        animationName: String,
        loopMode: LottiePlaybackLoopMode = .loop,
        contentMode: LottieContentMode = .aspectFit,
        autoplay: Bool = true,
        playbackSpeed: CGFloat = 1,
        @ViewBuilder fallback: () -> Fallback
    ) {
        self.animationName = animationName
        self.loopMode = loopMode
        self.contentMode = contentMode
        self.autoplay = autoplay
        self.playbackSpeed = playbackSpeed
        self.fallback = fallback()
    }

    var body: some View {
        if LottieAssetLoader.canLoadAnimation(named: animationName) {
            LottieAnimationViewRepresentable(
                animationName: animationName,
                loopMode: loopMode,
                contentMode: contentMode,
                autoplay: autoplay,
                playbackSpeed: playbackSpeed
            )
        } else {
            fallback
        }
    }
}

struct LottieAnimationViewRepresentable: UIViewRepresentable {
    let animationName: String
    let loopMode: LottiePlaybackLoopMode
    let contentMode: LottieContentMode
    let autoplay: Bool
    let playbackSpeed: CGFloat

    func makeCoordinator() -> Coordinator {
        Coordinator()
    }

    func makeUIView(context: Context) -> LottieAnimationView {
        let animationView = LottieAnimationView()
        animationView.backgroundBehavior = .pauseAndRestore
        configure(animationView, context: context)
        return animationView
    }

    func updateUIView(_ animationView: LottieAnimationView, context: Context) {
        configure(animationView, context: context)
    }

    private func configure(_ animationView: LottieAnimationView, context: Context) {
        if context.coordinator.currentAnimationName != animationName {
            animationView.animation = LottieAssetLoader.animation(named: animationName)
            context.coordinator.currentAnimationName = animationName
            context.coordinator.resetPlaybackState()
        }

        animationView.contentMode = contentMode.uiViewContentMode
        animationView.clipsToBounds = contentMode == .aspectFill
        animationView.loopMode = loopMode.lottieLoopMode
        animationView.animationSpeed = playbackSpeed

        updatePlayback(for: animationView, coordinator: context.coordinator)
    }

    private func updatePlayback(for animationView: LottieAnimationView, coordinator: Coordinator) {
        guard autoplay else {
            if animationView.isAnimationPlaying {
                animationView.stop()
            }
            return
        }

        switch loopMode {
        case .loop:
            if !animationView.isAnimationPlaying {
                animationView.play()
            }
        case .playOnce:
            guard !coordinator.hasStartedPlayOnce else { return }
            coordinator.hasStartedPlayOnce = true
            animationView.play { completed in
                if completed {
                    coordinator.hasCompletedPlayOnce = true
                }
            }
        }
    }

    final class Coordinator {
        var currentAnimationName: String?
        var hasStartedPlayOnce = false
        var hasCompletedPlayOnce = false

        func resetPlaybackState() {
            hasStartedPlayOnce = false
            hasCompletedPlayOnce = false
        }
    }
}

private enum LottieAssetLoader {
    static func canLoadAnimation(named name: String) -> Bool {
        animation(named: name) != nil
    }

    static func animation(named name: String) -> LottieAnimation? {
        if let animation = LottieAnimation.named(name, bundle: .main) {
            return animation
        }

        return LottieAnimation.named(
            name,
            bundle: .main,
            subdirectory: "Resources/Lottie"
        )
    }
}
