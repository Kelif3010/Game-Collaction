import SwiftUI

struct PerkToastView: View {
    let toast: GameManager.PerkToast
    
    var body: some View {
        HStack(spacing: 8) {
            Image(systemName: toast.icon)
            Text(toast.message)
                .font(.caption.bold())
        }
        .padding(.horizontal, 12)
        .padding(.vertical, 6)
        .background(.thinMaterial)
        .clipShape(Capsule())
        .shadow(radius: 4)
    }
}
