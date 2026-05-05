import SwiftUI

struct AppBackground: View {
    var body: some View {
        if #available(iOS 18.0, *) {
            MeshGradient(
                width: 3,
                height: 3,
                points: [
                    [0.0, 0.0], [0.5, 0.0], [1.0, 0.0],
                    [0.0, 0.5], [0.5, 0.5], [1.0, 0.5],
                    [0.0, 1.0], [0.5, 1.0], [1.0, 1.0]
                ],
                colors: [
                    Color(red: 0.05, green: 0.05, blue: 0.18),
                    Color(red: 0.08, green: 0.05, blue: 0.22),
                    Color(red: 0.05, green: 0.05, blue: 0.18),
                    Color(red: 0.10, green: 0.05, blue: 0.25),
                    Color(red: 0.12, green: 0.08, blue: 0.30),
                    Color(red: 0.08, green: 0.05, blue: 0.20),
                    Color(red: 0.05, green: 0.05, blue: 0.15),
                    Color(red: 0.10, green: 0.08, blue: 0.22),
                    Color(red: 0.05, green: 0.05, blue: 0.15)
                ]
            )
            .ignoresSafeArea()
        } else {
            LinearGradient(
                colors: [
                    Color(red: 0.05, green: 0.05, blue: 0.15),
                    Color(red: 0.1, green: 0.1, blue: 0.25)
                ],
                startPoint: .topLeading,
                endPoint: .bottomTrailing
            )
            .ignoresSafeArea()
        }
    }
}
