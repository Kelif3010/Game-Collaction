import SwiftUI

struct ImposterGameCard: View {
    @State private var scanAnimation = false
    @State private var glowPulse = false

    private let accentOrange    = Color(red: 1.0, green: 0.41, blue: 0.23)
    private let accentPink      = Color(red: 0.94, green: 0.16, blue: 0.47)
    private let backgroundDark  = Color(red: 0.16, green: 0.02, blue: 0.08)

    var body: some View {
        VStack(alignment: .leading, spacing: 12) {
            ZStack {
                Circle()
                    .stroke(accentOrange.opacity(0.4), lineWidth: 2)
                    .frame(width: 54, height: 54)
                    .scaleEffect(scanAnimation ? 1.3 : 1.0)
                    .opacity(scanAnimation ? 0 : 0.7)

                Circle()
                    .fill(
                        RadialGradient(
                            colors: [accentOrange.opacity(0.3), accentPink.opacity(0.1)],
                            center: .center, startRadius: 0, endRadius: 25
                        )
                    )
                    .frame(width: 50, height: 50)
                    .overlay(Circle().stroke(accentOrange.opacity(0.5), lineWidth: 1.5))

                Image(systemName: "person.fill.viewfinder")
                    .font(.title2)
                    .foregroundStyle(
                        LinearGradient(colors: [accentOrange, accentPink], startPoint: .topLeading, endPoint: .bottomTrailing)
                    )
                    .shadow(color: accentOrange.opacity(0.6), radius: 4)
            }

            Spacer()

            VStack(alignment: .leading, spacing: 4) {
                HStack(spacing: 6) {
                    Text("Spy")
                        .font(.system(.title3, design: .rounded).bold())
                        .foregroundStyle(.white)
                    Text("🔒").font(.system(size: 10))
                }
                Text("TOP SECRET")
                    .font(.system(size: 10, weight: .bold, design: .monospaced))
                    .foregroundStyle(accentOrange.opacity(0.8))
                    .tracking(1.5)
            }
        }
        .frame(maxWidth: .infinity, alignment: .leading)
        .frame(height: 160)
        .padding()
        .background(
            ZStack {
                LinearGradient(
                    colors: [Color.black, backgroundDark, Color(red: 0.20, green: 0.02, blue: 0.10)],
                    startPoint: .topLeading,
                    endPoint: .bottomTrailing
                )
                RadialGradient(
                    colors: [accentOrange.opacity(glowPulse ? 0.12 : 0.06), Color.clear],
                    center: .topLeading, startRadius: 0, endRadius: 180
                )
                VStack(spacing: 4) {
                    ForEach(0..<40, id: \.self) { _ in
                        Rectangle().fill(Color.white.opacity(0.02)).frame(height: 1)
                    }
                }
                VStack {
                    Spacer()
                    HStack {
                        Spacer()
                        ZStack {
                            Circle().stroke(accentOrange.opacity(0.1), lineWidth: 1).frame(width: 40, height: 40)
                            Circle().stroke(accentOrange.opacity(0.05), lineWidth: 1).frame(width: 25, height: 25)
                        }
                        .offset(x: 15, y: 15)
                    }
                }
            }
        )
        .clipShape(RoundedRectangle(cornerRadius: 16))
        .overlay(
            RoundedRectangle(cornerRadius: 16)
                .stroke(
                    LinearGradient(
                        colors: [accentOrange.opacity(0.5), accentPink.opacity(0.2)],
                        startPoint: .topLeading,
                        endPoint: .bottomTrailing
                    ),
                    lineWidth: 1.5
                )
        )
        .shadow(color: accentOrange.opacity(0.25), radius: 12, x: 0, y: 5)
        .shadow(color: .black.opacity(0.4), radius: 10, x: 0, y: 5)
        .onAppear {
            withAnimation(.easeInOut(duration: 1.5).repeatForever(autoreverses: false)) { scanAnimation = true }
            withAnimation(.easeInOut(duration: 2.5).repeatForever(autoreverses: true)) { glowPulse = true }
        }
    }
}
