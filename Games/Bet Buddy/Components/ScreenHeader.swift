import SwiftUI

struct ScreenHeader: View {
    var title: String
    var showBack: Bool = true
    var backAction: (() -> Void)? = nil

    @Environment(\.dismiss) private var dismiss

    var body: some View {
        HStack {
            if showBack {
                Button {
                    backAction?() ?? dismiss()
                } label: {
                    Image(systemName: "chevron.left")
                        .font(.headline.bold())
                        .foregroundStyle(.white)
                        .frame(width: 36, height: 36)
                        .background(Color.white.opacity(0.08))
                        .clipShape(RoundedRectangle(cornerRadius: 12))
                }
            } else {
                Color.clear.frame(width: 36, height: 36)
            }

            Spacer()

            Text(LocalizedStringKey(title))
                .font(.title3.bold())
                .foregroundStyle(.white)

            Spacer()

            Color.clear.frame(width: 36, height: 36)
        }
        .padding(.bottom, 8)
    }
}
