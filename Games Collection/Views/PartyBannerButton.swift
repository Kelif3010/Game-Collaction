import SwiftUI

struct PartyBannerButton: View {
    @Binding var isPresented: Bool

    var body: some View {
        Button {
            isPresented = true
        } label: {
            HStack(spacing: 14) {
                ZStack {
                    Circle()
                        .fill(.black.opacity(0.15))
                        .frame(width: 44, height: 44)
                    Image(systemName: "crown.fill")
                        .font(.system(size: 20, weight: .bold))
                        .foregroundStyle(.black.opacity(0.7))
                }

                VStack(alignment: .leading, spacing: 2) {
                    Text("Party starten")
                        .font(.system(size: 17, weight: .bold, design: .rounded))
                        .foregroundStyle(.black)
                    Text("Mehrere Spiele · Gesamtwertung")
                        .font(.system(size: 12))
                        .foregroundStyle(.black.opacity(0.55))
                }

                Spacer()

                Image(systemName: "chevron.right")
                    .font(.system(size: 13, weight: .semibold))
                    .foregroundStyle(.black.opacity(0.4))
            }
            .padding(.horizontal, 18)
            .padding(.vertical, 14)
            .background(
                LinearGradient(
                    colors: [
                        Color(red: 1.0, green: 0.83, blue: 0.15),
                        Color(red: 1.0, green: 0.65, blue: 0.05)
                    ],
                    startPoint: .leading,
                    endPoint: .trailing
                ),
                in: RoundedRectangle(cornerRadius: 18)
            )
            .shadow(
                color: Color(red: 1.0, green: 0.65, blue: 0.05).opacity(0.35),
                radius: 12, y: 6
            )
        }
        .padding(.horizontal)
        .padding(.top, 8)
    }
}
