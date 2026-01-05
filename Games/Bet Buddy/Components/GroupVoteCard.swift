import SwiftUI

struct GroupVoteCard: View {
    let group: GroupInfo
    var onIncrement: () -> Void
    var onDecrement: () -> Void
    var locked: Bool
    var isLeader: Bool
    var showLeader: Bool

    @State private var animate = false

    var body: some View {
        ZStack {
            RoundedRectangle(cornerRadius: 20)
                .fill(group.color.gradient.opacity(showLeader && isLeader ? 0.35 : 0.2))
                .overlay(
                    RoundedRectangle(cornerRadius: 20)
                        .stroke(group.color.primary.opacity(0.5), lineWidth: 1)
                )
                .overlay(alignment: .center) {
                    if showLeader && isLeader {
                        Image(systemName: "crown.fill")
                            .font(.system(size: 120))
                            .foregroundStyle(Color.white.opacity(0.15))
                            .offset(y: -6)
                    }
                }

            HStack {
                Button {
                    guard !locked else { return }
                    onDecrement()
                    HapticsService.impact(.light)
                } label: {
                    Image(systemName: "minus")
                        .font(.system(size: 36, weight: .bold, design: .rounded))
                        .foregroundStyle(.white)
                        .frame(width: 64, height: 64)
                        .background(Color.white.opacity(0.08))
                        .clipShape(Circle())
                }
                .buttonStyle(.plain)
                .padding(.leading, 12)

                Spacer()

                Button {
                    guard !locked else { return }
                    onIncrement()
                    HapticsService.impact(.medium)
                    withAnimation(.spring(response: 0.3, dampingFraction: 0.7)) {
                        animate.toggle()
                    }
                } label: {
                    Image(systemName: "plus")
                        .font(.system(size: 36, weight: .bold, design: .rounded))
                        .foregroundStyle(.white)
                        .frame(width: 64, height: 64)
                        .background(Color.white.opacity(0.12))
                        .clipShape(Circle())
                }
                .buttonStyle(.plain)
                .padding(.trailing, 12)
            }

            VStack {
                Spacer()
                Text(LocalizedStringKey(group.displayName))
                    .foregroundStyle(.white)
                    .font(.headline)
                    .padding(.bottom, 14)
            }
        }
        .frame(maxWidth: .infinity, minHeight: 160)
        .scaleEffect(animate ? 1.03 : 1.0)
        .animation(.easeOut(duration: 0.2), value: animate)
    }
}
