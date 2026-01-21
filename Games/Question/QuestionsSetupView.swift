import SwiftUI

struct QuestionsSetupView: View {
    @ObservedObject var appModel: AppModel
    @Binding var selectedCategory: QuestionsCategory?
    @Binding var numberOfLiars: Int
    @Binding var discussionTime: TimeInterval
    var onStartGame: () -> Void
    
    // Navigation State
    @Environment(\.dismiss) var dismiss
    @State private var showPlayerSheet = false
    @State private var showCategorySheet = false
    @State private var showSettingsSheet = false
    @State private var showLeaderboardSheet = false
    @State private var showInfoSheet = false
    
    // Validierung
    private var playerCount: Int { appModel.players.count }
    private var maxLiars: Int { max(0, playerCount > 1 ? playerCount - 1 : 0) }
    private var canStart: Bool {
        guard let cat = selectedCategory else { return false }
        return playerCount >= 3 && numberOfLiars >= 1 && numberOfLiars <= maxLiars && !cat.promptPairs.isEmpty
    }

    var body: some View {
        NavigationStack {
            ZStack {
                // Hintergrund
                QuestionsBackgroundView().ignoresSafeArea()
                
                VStack(spacing: 0) {
                    // MARK: - Top Bar
                    HStack {
                        Button {
                            dismiss()
                        } label: {
                            Image(systemName: "chevron.left")
                                .font(.headline.bold())
                                .foregroundStyle(.white)
                                .frame(width: 36, height: 36)
                                .background(Color.white.opacity(0.1))
                                .clipShape(Circle())
                        }
                        
                        Spacer()
                        
                        HStack(spacing: 12) {
                            // Auswertung
                            Button { showLeaderboardSheet = true } label: {
                                Image(systemName: "chart.line.uptrend.xyaxis")
                                    .font(.headline)
                                    .foregroundStyle(.yellow)
                                    .frame(width: 36, height: 36)
                                    .background(Color.white.opacity(0.1))
                                    .clipShape(Circle())
                            }
                            
                            // Akte (Kategorie)
                            Button { showCategorySheet = true } label: {
                                Image(systemName: "doc.text.magnifyingglass")
                                    .font(.headline)
                                    .foregroundStyle(.orange)
                                    .frame(width: 36, height: 36)
                                    .background(Color.white.opacity(0.1))
                                    .clipShape(Circle())
                            }
                            
                            // Zahnrad (Settings)
                            Button { showSettingsSheet = true } label: {
                                Image(systemName: "slider.horizontal.3")
                                    .font(.headline)
                                    .foregroundStyle(.gray)
                                    .frame(width: 36, height: 36)
                                    .background(Color.white.opacity(0.1))
                                    .clipShape(Circle())
                            }
                            
                            // Info
                            Button { showInfoSheet = true } label: {
                                Image(systemName: "info.circle.fill")
                                    .font(.headline.bold())
                                    .foregroundStyle(.white)
                                    .frame(width: 36, height: 36)
                                    .background(Color.white.opacity(0.1))
                                    .clipShape(Circle())
                            }
                        }
                    }
                    .padding(.horizontal)
                    .padding(.top, 20)
                    .padding(.bottom, 10)
                    
                    ScrollView {
                        VStack(spacing: 16) {
                            
                            QuestionsGroupedCard {
                                // Spieler Row
                                Button {
                                    showPlayerSheet = true
                                } label: {
                                    QuestionsRowCell(
                                        icon: "person.3.fill",
                                        title: "Verdächtige",
                                        value: "\(playerCount)",
                                        tint: .blue
                                    )
                                }
                                
                                // Lügner Row with Stepper
                                HStack(spacing: 12) {
                                    QuestionsIconBadge(systemName: "waveform.path.ecg", tint: .red)
                                    Text("Lügner")
                                        .font(.body)
                                        .fontWeight(.semibold)
                                        .foregroundColor(.white)
                                    Spacer()
                                    
                                    HStack(spacing: 8) {
                                        Button {
                                            if numberOfLiars > 1 { numberOfLiars -= 1 }
                                        } label: {
                                            Image(systemName: "minus")
                                                .font(.system(size: 16, weight: .semibold))
                                                .frame(width: 30, height: 30)
                                                .background(Color.white.opacity(0.12))
                                                .foregroundColor(.white)
                                                .clipShape(Circle())
                                        }
                                        
                                        Text("\(numberOfLiars)")
                                            .font(.callout)
                                            .foregroundColor(.white)
                                            .frame(minWidth: 24)
                                            
                                        Button {
                                            if numberOfLiars < maxLiars { numberOfLiars += 1 }
                                        } label: {
                                            Image(systemName: "plus")
                                                .font(.system(size: 16, weight: .semibold))
                                                .frame(width: 30, height: 30)
                                                .background(Color.white.opacity(0.12))
                                                .foregroundColor(.white)
                                                .clipShape(Circle())
                                        }
                                    }
                                }
                                .questionsRowStyle()
                                
                                // Timer Row (Slider)
                                VStack(spacing: 10) {
                                    HStack(spacing: 12) {
                                        QuestionsIconBadge(systemName: "timer", tint: .green)
                                    Text("Befragung")
                                        .font(.body)
                                        .fontWeight(.semibold)
                                        .foregroundColor(.white)
                                        Spacer()
                                        Text(timeString)
                                            .font(.callout)
                                            .foregroundStyle(QuestionsStyle.mutedText)
                                    }

                                    Slider(value: Binding(
                                        get: { Double(discussionTime) },
                                        set: { discussionTime = TimeInterval($0) }
                                    ), in: 60...1800, step: 60)
                                    .tint(.green)
                                }
                                .questionsRowStyle()
                                
                                // Kategorie Row
                                Button {
                                    showCategorySheet = true
                                } label: {
                                    QuestionsRowCell(
                                        icon: "folder.fill",
                                        title: "Fallakte",
                                        value: selectedCategory?.name ?? "Wählen",
                                        tint: .orange
                                    )
                                }
                            }
                        }
                        .padding(.horizontal, QuestionsStyle.padding)
                        .padding(.top, 16)
                        .padding(.bottom, 120)
                    }
                }
            }
            .toolbar(.hidden, for: .navigationBar)
            .safeAreaInset(edge: .bottom) {
                VStack(spacing: 10) {
                    QuestionsPrimaryButton(title: "Test starten") {
                        onStartGame()
                    }
                    .disabled(!canStart)
                    
                    if !canStart {
                        Text(validationMessage)
                            .font(.footnote)
                            .foregroundStyle(QuestionsStyle.mutedText)
                            .multilineTextAlignment(.center)
                    }
                }
                .padding(.horizontal, 20)
                .padding(.bottom, 12)
            }
            .sheet(isPresented: $showPlayerSheet) {
                QuestionsPlayerManagementSheet(appModel: appModel)
                    .presentationDetents([.medium, .large])
                    .presentationDragIndicator(.visible)
                    .presentationCornerRadius(28)
                    .presentationBackground(.clear)
            }
            .sheet(isPresented: $showCategorySheet) {
                QuestionsCategorySheet(selectedCategory: $selectedCategory)
                    .presentationDetents([.large])
                    .presentationDragIndicator(.visible)
                    .presentationCornerRadius(28)
                    .presentationBackground(.clear)
            }
            .sheet(isPresented: $showSettingsSheet) {
                QuestionsSettingsSheet()
                    .presentationDetents([.medium])
                    .presentationDragIndicator(.visible)
                    .presentationCornerRadius(28)
                    .presentationBackground(.clear)
            }
            .sheet(isPresented: $showLeaderboardSheet) {
                QuestionsPlaceholderSheet(title: "Messprotokoll", icon: "chart.line.uptrend.xyaxis")
                    .presentationDetents([.medium])
                    .presentationDragIndicator(.visible)
                    .presentationCornerRadius(28)
                    .presentationBackground(.clear)
            }
            .sheet(isPresented: $showInfoSheet) {
                QuestionsPlaceholderSheet(title: "Handbuch", icon: "book.fill")
                    .presentationDetents([.large])
                    .presentationDragIndicator(.visible)
                    .presentationCornerRadius(28)
                    .presentationBackground(.clear)
            }
        }
    }
    
    private var timeString: String {
        if discussionTime == 0 {
            return NSLocalizedString("Unbegrenzt", comment: "")
        } else {
            let minutes = Int(discussionTime) / 60
            let seconds = Int(discussionTime) % 60
            if seconds == 0 {
                return "\(minutes) Min"
            } else {
                return "\(minutes):\(String(format: "%02d", seconds)) Min"
            }
        }
    }
    
    private var validationMessage: LocalizedStringKey {
        if playerCount < 3 { return "Mindestens 3 Verdächtige benötigt." }
        if selectedCategory == nil { return "Bitte eine Akte wählen." }
        return ""
    }
}
