import SwiftUI
#if canImport(Lottie)
import Lottie
#endif

struct SharedLottieView: UIViewRepresentable {
    enum LoopMode {
        case playOnce
        case loop
        case autoReverse
    }

    var filename: String
    var loopMode: LoopMode = .loop
    var isPlaying: Bool = true
    var contentMode: UIView.ContentMode = .scaleAspectFit
    var animationSpeed: CGFloat = 1.0
    var playTrigger: Int = 0
    var onCompleted: (() -> Void)? = nil

    private var resolvedName: String {
        let name = filename.replacingOccurrences(of: ".lottie", with: "")
        return name.replacingOccurrences(of: ".json", with: "")
    }

    private var hasDotLottieResource: Bool {
        Bundle.main.path(forResource: resolvedName, ofType: "lottie") != nil
    }

    func makeCoordinator() -> Coordinator {
        Coordinator()
    }

    func makeUIView(context: Context) -> UIView {
        let view = UIView(frame: .zero)
        view.backgroundColor = .clear

        #if canImport(Lottie)
        let animationView = makeAnimationView(coordinator: context.coordinator)
        context.coordinator.install(animationView: animationView, in: view, resolvedName: resolvedName)
        applyConfiguration(to: animationView)

        if isPlaying {
            if hasDotLottieResource {
                context.coordinator.shouldPlayWhenReady = true
            } else {
                play(animationView, coordinator: context.coordinator)
            }
        }
        #else
        installFallback(in: view)
        #endif

        return view
    }

    func updateUIView(_ uiView: UIView, context: Context) {
        #if canImport(Lottie)
        let animationView: LottieAnimationView
        if context.coordinator.resolvedName != resolvedName {
            context.coordinator.resetLoadingState()
            animationView = makeAnimationView(coordinator: context.coordinator)
            context.coordinator.install(animationView: animationView, in: uiView, resolvedName: resolvedName)
        } else {
            animationView = context.coordinator.animationView(in: uiView) {
                makeAnimationView(coordinator: context.coordinator)
            }
        }

        applyConfiguration(to: animationView)

        switch loopMode {
        case .playOnce:
            if isPlaying, context.coordinator.lastPlayTrigger != playTrigger {
                if hasDotLottieResource, !context.coordinator.isDotLottieLoaded {
                    context.coordinator.shouldPlayWhenReady = true
                } else {
                    play(animationView, coordinator: context.coordinator)
                }
            } else if !isPlaying {
                animationView.stop()
            }
        case .loop, .autoReverse:
            if isPlaying {
                if hasDotLottieResource, !context.coordinator.isDotLottieLoaded {
                    context.coordinator.shouldPlayWhenReady = true
                } else if !animationView.isAnimationPlaying {
                    animationView.play()
                }
            } else {
                animationView.stop()
            }
        }
        #endif
    }

    #if canImport(Lottie)
    private func makeAnimationView(coordinator: Coordinator) -> LottieAnimationView {
        if hasDotLottieResource {
            return LottieAnimationView(dotLottieName: resolvedName) { animationView, error in
                coordinator.isDotLottieLoaded = (error == nil)

                guard error == nil else { return }

                applyConfiguration(to: animationView)

                if coordinator.shouldPlayWhenReady || isPlaying {
                    coordinator.shouldPlayWhenReady = false
                    play(animationView, coordinator: coordinator)
                }
            }
        }
        return LottieAnimationView(name: resolvedName)
    }

    private func applyConfiguration(to animationView: LottieAnimationView) {
        animationView.contentMode = contentMode
        animationView.animationSpeed = animationSpeed
        animationView.backgroundBehavior = .pauseAndRestore

        switch loopMode {
        case .playOnce:
            animationView.loopMode = .playOnce
        case .loop:
            animationView.loopMode = .loop
        case .autoReverse:
            animationView.loopMode = .autoReverse
        }
    }

    private func play(_ animationView: LottieAnimationView, coordinator: Coordinator) {
        coordinator.lastPlayTrigger = playTrigger

        if loopMode == .playOnce {
            animationView.currentProgress = 0
            animationView.play { finished in
                if finished {
                    onCompleted?()
                }
            }
        } else {
            animationView.play()
        }
    }
    #endif

    private func installFallback(in view: UIView) {
        let label = UILabel()
        label.text = "Lottie: \(filename)"
        label.textColor = .orange
        label.font = .systemFont(ofSize: 10, weight: .bold)
        label.textAlignment = .center
        label.numberOfLines = 0
        label.translatesAutoresizingMaskIntoConstraints = false

        let border = UIView()
        border.layer.borderColor = UIColor.orange.withAlphaComponent(0.5).cgColor
        border.layer.borderWidth = 1
        border.layer.cornerRadius = 8
        border.translatesAutoresizingMaskIntoConstraints = false

        view.addSubview(border)
        view.addSubview(label)

        NSLayoutConstraint.activate([
            border.topAnchor.constraint(equalTo: view.topAnchor),
            border.bottomAnchor.constraint(equalTo: view.bottomAnchor),
            border.leadingAnchor.constraint(equalTo: view.leadingAnchor),
            border.trailingAnchor.constraint(equalTo: view.trailingAnchor),
            label.centerXAnchor.constraint(equalTo: view.centerXAnchor),
            label.centerYAnchor.constraint(equalTo: view.centerYAnchor),
            label.leadingAnchor.constraint(equalTo: view.leadingAnchor, constant: 4),
            label.trailingAnchor.constraint(equalTo: view.trailingAnchor, constant: -4)
        ])
    }

    final class Coordinator {
        fileprivate var resolvedName: String?
        fileprivate var lastPlayTrigger: Int?
        fileprivate var isDotLottieLoaded = false
        fileprivate var shouldPlayWhenReady = false

        fileprivate func resetLoadingState() {
            isDotLottieLoaded = false
            shouldPlayWhenReady = false
        }

        #if canImport(Lottie)
        fileprivate func install(animationView: LottieAnimationView, in container: UIView, resolvedName: String) {
            container.subviews.forEach { $0.removeFromSuperview() }
            animationView.translatesAutoresizingMaskIntoConstraints = false
            container.addSubview(animationView)
            NSLayoutConstraint.activate([
                animationView.topAnchor.constraint(equalTo: container.topAnchor),
                animationView.bottomAnchor.constraint(equalTo: container.bottomAnchor),
                animationView.leadingAnchor.constraint(equalTo: container.leadingAnchor),
                animationView.trailingAnchor.constraint(equalTo: container.trailingAnchor)
            ])
            self.resolvedName = resolvedName
        }

        fileprivate func animationView(in container: UIView, make: () -> LottieAnimationView) -> LottieAnimationView {
            if let existing = container.subviews.first(where: { $0 is LottieAnimationView }) as? LottieAnimationView {
                return existing
            }
            let animationView = make()
            install(animationView: animationView, in: container, resolvedName: resolvedName ?? "")
            return animationView
        }
        #endif
    }
}
