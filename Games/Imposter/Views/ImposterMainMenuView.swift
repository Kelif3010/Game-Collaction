import SwiftUI

struct ImposterMainMenuView: View {
    @StateObject private var gameSettings = GameSettings()
    @State private var showingGameFlow = false
    
    var body: some View {
        NavigationView {
            VStack(spacing: 30) {
                // App Logo/Title
                VStack(spacing: 10) {
                    Image(systemName: "person.2.circle.fill")
                        .font(.system(size: 80))
                        .foregroundColor(.orange)
                    
                    Text("IMPOSTER")
                        .font(.largeTitle)
                        .fontWeight(.bold)
                        .foregroundColor(.primary)
                    
                    Text("Das Spion-Spiel")
                        .font(.subheadline)
                        .foregroundColor(.secondary)
                }
                .padding(.top, 50)
                
                Spacer()
                
                // Hauptmenü-Buttons
                VStack(spacing: 20) {
                    Button {
                        showingGameFlow = true
                    } label: {
                        MenuButton(title: "Neues Spiel", icon: "play.circle.fill")
                    }
                    
                    NavigationLink(destination: CategoriesView().environmentObject(gameSettings)) {
                        MenuButton(title: "Kategorien verwalten", icon: "folder.fill")
                    }
                    
                    NavigationLink(destination: ImposterSettingsView()) {
                        MenuButton(title: "Einstellungen", icon: "gearshape.fill")
                    }
                }
                
                Spacer()
                
                Text("Version 1.0")
                    .font(.caption)
                    .foregroundColor(.secondary)
                    .padding(.bottom, 20)
            }
            .padding(.horizontal, 30)
            .background(
                LinearGradient(
                    colors: [Color.blue.opacity(0.1), Color.purple.opacity(0.1)],
                    startPoint: .topLeading,
                    endPoint: .bottomTrailing
                )
            )
        }
#if os(iOS)
        .navigationViewStyle(StackNavigationViewStyle())
#endif
        .fullScreenCover(isPresented: $showingGameFlow) {
            GameFlowContainer(gameSettings: gameSettings)
        }
    }
}

private struct GameFlowContainer: View {
    @ObservedObject var gameSettings: GameSettings
    
    var body: some View {
        GameSetupView()
            .environmentObject(gameSettings)
    }
}

struct MenuButton: View {
    let title: String
    let icon: String
    
    var body: some View {
        HStack {
            Image(systemName: icon)
                .font(.title2)
                .foregroundColor(.white)
            
            Text(title)
                .font(.headline)
                .foregroundColor(.white)
            
            Spacer()
            
            Image(systemName: "chevron.right")
                .font(.title3)
                .foregroundColor(.white.opacity(0.7))
        }
        .padding(.horizontal, 25)
        .padding(.vertical, 18)
        .background(
            RoundedRectangle(cornerRadius: 15)
                .fill(LinearGradient(
                    colors: [Color.orange, Color.red],
                    startPoint: .leading,
                    endPoint: .trailing
                ))
                .shadow(color: .black.opacity(0.2), radius: 5, x: 0, y: 3)
        )
    }
}

#Preview {
    ImposterMainMenuView()
}
