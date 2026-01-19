import SwiftUI

struct QuestionsCategorySheet: View {
    @Binding var selectedCategory: QuestionsCategory?
    @Environment(\.dismiss) var dismiss
    
    var body: some View {
        ZStack {
            QuestionsStyle.backgroundGradient.ignoresSafeArea()
            
            VStack(spacing: 0) {
                QuestionsSheetHeader(title: "Kategorie wählen") {
                    dismiss()
                }
                .padding(.horizontal, QuestionsStyle.padding)
                
                ScrollView {
                    VStack(spacing: 12) {
                        ForEach(QuestionsDefaults.all) { category in
                            Button {
                                selectedCategory = category
                                dismiss()
                            } label: {
                                HStack(spacing: 12) {
                                    QuestionsIconBadge(systemName: "folder.fill", tint: .orange)
                                    
                                    VStack(alignment: .leading, spacing: 4) {
                                        Text(LocalizedStringKey(category.name))
                                            .font(.headline)
                                            .foregroundStyle(.white)
                                        Text("\(category.promptPairs.count) Fragen")
                                            .font(.caption)
                                            .foregroundStyle(QuestionsStyle.mutedText)
                                    }
                                    
                                    Spacer()
                                    
                                    if selectedCategory?.id == category.id {
                                        Image(systemName: "checkmark.circle.fill")
                                            .foregroundStyle(.green)
                                            .font(.headline)
                                    } else {
                                        Image(systemName: "circle")
                                            .foregroundStyle(.white.opacity(0.3))
                                            .font(.headline)
                                    }
                                }
                                .questionsRowStyle()
                            }
                            .buttonStyle(.plain)
                        }
                    }
                    .padding(QuestionsStyle.padding)
                }
            }
        }
    }
}
