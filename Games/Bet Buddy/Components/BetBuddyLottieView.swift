import SwiftUI

struct BetBuddyLottieView: View {
    var filename: String
    var loopMode: LoopMode = .loop
    var isPlaying: Bool = true
    var contentMode: UIView.ContentMode = .scaleAspectFit
    var animationSpeed: CGFloat = 1.0
    var playTrigger: Int = 0
    var onCompleted: (() -> Void)? = nil

    enum LoopMode {
        case playOnce
        case loop
        case autoReverse
    }

    var body: some View {
        SharedLottieView(
            filename: filename,
            loopMode: sharedLoopMode,
            isPlaying: isPlaying,
            contentMode: contentMode,
            animationSpeed: animationSpeed,
            playTrigger: playTrigger,
            onCompleted: onCompleted
        )
    }

    private var sharedLoopMode: SharedLottieView.LoopMode {
        switch loopMode {
        case .playOnce:
            .playOnce
        case .loop:
            .loop
        case .autoReverse:
            .autoReverse
        }
    }
}

#Preview {
    BetBuddyLottieView(filename: "3D coin flip")
        .frame(width: 200, height: 200)
        .background(BetBuddyTheme.background)
}
