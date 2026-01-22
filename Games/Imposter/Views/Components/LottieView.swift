//
//  LottieView.swift
//  Imposter
//
//  Created for Games Collection
//

import SwiftUI
#if canImport(Lottie)
import Lottie
#endif

struct LottieView: UIViewRepresentable {
    var filename: String
    var loopMode: LoopMode = .loop
    var isPlaying: Bool = true
    var contentMode: UIView.ContentMode = .scaleAspectFit
    var animationSpeed: CGFloat = 1.0

    private var resolvedName: String {
        let name = filename.replacingOccurrences(of: ".lottie", with: "")
        return name.replacingOccurrences(of: ".json", with: "")
    }

    private var hasDotLottieResource: Bool {
        Bundle.main.path(forResource: resolvedName, ofType: "lottie") != nil
    }
    
    enum LoopMode {
        case playOnce
        case loop
        case autoReverse
    }

    func makeUIView(context: Context) -> UIView {
        let view = UIView(frame: .zero)
        view.backgroundColor = .clear
        
        #if canImport(Lottie)
        let animationView: LottieAnimationView
        if hasDotLottieResource {
            animationView = LottieAnimationView(dotLottieName: resolvedName)
        } else {
            animationView = LottieAnimationView(name: resolvedName)
        }
        animationView.contentMode = contentMode
        
        switch loopMode {
        case .playOnce: animationView.loopMode = .playOnce
        case .loop: animationView.loopMode = .loop
        case .autoReverse: animationView.loopMode = .autoReverse
        }
        animationView.animationSpeed = animationSpeed
        
        animationView.backgroundBehavior = .pauseAndRestore
        animationView.translatesAutoresizingMaskIntoConstraints = false
        view.addSubview(animationView)
        
        NSLayoutConstraint.activate([
            animationView.heightAnchor.constraint(equalTo: view.heightAnchor),
            animationView.widthAnchor.constraint(equalTo: view.widthAnchor)
        ])
        
        // Speichere den aktuellen Dateinamen als Tag oder in einer Subclass (hier vereinfacht über context nicht nötig, da updateUIView das regelt)
        
        // Initial play state
        if isPlaying {
            animationView.play()
        }
        #else
        // Fallback: Wenn Lottie nicht installiert ist (oder in Preview ohne Package)
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
        #endif
        
        return view
    }

    func updateUIView(_ uiView: UIView, context: Context) {
        #if canImport(Lottie)
        guard let animationView = uiView.subviews.first(where: { $0 is LottieAnimationView }) as? LottieAnimationView else { return }
        
        animationView.animationSpeed = animationSpeed
        if isPlaying {
            if !animationView.isAnimationPlaying {
                animationView.play()
            }
        } else {
            animationView.stop()
        }
        #endif
    }
}
