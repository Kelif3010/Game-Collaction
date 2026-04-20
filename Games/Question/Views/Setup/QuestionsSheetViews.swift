import SwiftUI

struct QuestionsSettingsSheet: View {
    @Environment(\.dismiss) var dismiss
    
    var body: some View {
        ZStack {
            QuestionsStyle.backgroundGradient.ignoresSafeArea()
            VStack {
                QuestionsSheetHeader(title: "Einstellungen") {
                    dismiss()
                }
                .padding(.horizontal, QuestionsStyle.padding)
                
                Spacer()
                Text(LocalizedStringKey("Hier könnten Spieleinstellungen sein."))
                    .foregroundStyle(QuestionsStyle.mutedText)
                Spacer()
            }
        }
    }
}

struct QuestionsPlaceholderSheet: View {
    let title: String
    let icon: String
    @Environment(\.dismiss) var dismiss
    
    var body: some View {
        ZStack {
            QuestionsStyle.backgroundGradient.ignoresSafeArea()
            VStack(spacing: 20) {
                QuestionsSheetHeader(title: title) {
                    dismiss()
                }
                .padding(.horizontal, QuestionsStyle.padding)
                
                Spacer()
                
                Image(systemName: icon)
                    .font(.system(size: 60))
                    .foregroundStyle(.white.opacity(0.2))
                
                Text(LocalizedStringKey(title))
                    .font(.title2.bold())
                    .foregroundStyle(.white)
                
                Spacer()
            }
        }
    }
}
