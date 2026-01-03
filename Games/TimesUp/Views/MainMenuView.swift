//
//  MainMenuView.swift
//  TimesUp
//
//  Created by Ken  on 23.09.25.
//

import SwiftUI

struct MainMenuView: View {
    @ObservedObject var categoryManager: CategoryManager
    @State private var showSettings = false
    @State private var showAppSettings = false
    @State private var showCategoryManagement = false
    @State private var showGame = false
    @StateObject private var devGameManager: GameManager
    
    init(categoryManager: CategoryManager) {
        _categoryManager = ObservedObject(wrappedValue: categoryManager)
        _devGameManager = StateObject(wrappedValue: GameManager(categoryManager: categoryManager))
    }
    
    var body: some View {
        NavigationView {
            VStack(spacing: 40) {
                Spacer()
                
                // App Logo/Title
                VStack(spacing: 20) {
                    Image(systemName: "timer")
                        .font(.system(size: 80, weight: .bold))
                        .foregroundStyle(
                            LinearGradient(
                                colors: [.blue, .purple],
                                startPoint: .topLeading,
                                endPoint: .bottomTrailing
                            )
                        )
                    
                    Text("Time's Up!")
                        .font(.largeTitle)
                        .fontWeight(.bold)
                        .foregroundStyle(
                            LinearGradient(
                                colors: [.blue, .purple],
                                startPoint: .leading,
                                endPoint: .trailing
                            )
                        )
                    
                    Text("Das ultimative Ratespiel")
                        .font(.title3)
                        .foregroundColor(.secondary)
                }
                
                Spacer()
                
                // Menu Buttons
                VStack(spacing: 20) {
                    // Neues Spiel Button
                    Button(action: {
                        showSettings = true
                    }) {
                        HStack {
                            Image(systemName: "play.fill")
                                .font(.title2)
                            Text("Neues Spiel")
                                .font(.title2)
                                .fontWeight(.semibold)
                        }
                        .foregroundColor(.white)
                        .frame(maxWidth: .infinity)
                        .frame(height: 60)
                        .background(
                            LinearGradient(
                                colors: [.blue, .purple],
                                startPoint: .leading,
                                endPoint: .trailing
                            )
                        )
                        .cornerRadius(15)
                    }
                    
                    // Kategorien verwalten Button
                    Button(action: {
                        showCategoryManagement = true
                    }) {
                        HStack {
                            Image(systemName: "folder.badge.gearshape")
                                .font(.title2)
                            Text("Kategorien verwalten")
                                .font(.title2)
                                .fontWeight(.semibold)
                        }
                        .foregroundColor(.orange)
                        .frame(maxWidth: .infinity)
                        .frame(height: 60)
                        .background(Color(.systemBackground))
                        .cornerRadius(15)
                        .overlay(
                            RoundedRectangle(cornerRadius: 15)
                                .stroke(Color.orange, lineWidth: 2)
                        )
                        .shadow(color: .primary.opacity(0.1), radius: 5, x: 0, y: 2)
                    }
                    
                    // App-Einstellungen Button (Sprachen)
                    Button(action: {
                        showAppSettings = true
                    }) {
                        HStack {
                            Image(systemName: "gearshape.fill")
                                .font(.title2)
                            Text("Einstellungen")
                                .font(.title2)
                                .fontWeight(.semibold)
                        }
                        .foregroundColor(.blue)
                        .frame(maxWidth: .infinity)
                        .frame(height: 60)
                        .background(Color(.systemBackground))
                        .cornerRadius(15)
                        .overlay(
                            RoundedRectangle(cornerRadius: 15)
                                .stroke(Color.blue, lineWidth: 2)
                        )
                        .shadow(color: .primary.opacity(0.1), radius: 5, x: 0, y: 2)
                    }
                    
                    // Spielregeln Button
                    Button(action: {
                        // TODO: Spielregeln anzeigen
                    }) {
                        HStack {
                            Image(systemName: "questionmark.circle")
                                .font(.title2)
                            Text("Spielregeln")
                                .font(.title2)
                                .fontWeight(.semibold)
                        }
                        .foregroundColor(.blue)
                        .frame(maxWidth: .infinity)
                        .frame(height: 60)
                        .background(Color(.systemBackground))
                        .cornerRadius(15)
                        .overlay(
                            RoundedRectangle(cornerRadius: 15)
                                .stroke(Color.blue, lineWidth: 2)
                        )
                        .shadow(color: .primary.opacity(0.1), radius: 5, x: 0, y: 2)
                    }
                    
                    #if DEBUG
                    Button(action: {
                        devGameManager.configureDevTestGame()
                        showGame = true
                    }) {
                        HStack {
                            Image(systemName: "wrench.and.screwdriver.fill")
                                .font(.title2)
                            Text("Test")
                                .font(.title2)
                                .fontWeight(.semibold)
                        }
                        .foregroundColor(.white)
                        .frame(maxWidth: .infinity)
                        .frame(height: 60)
                        .background(
                            LinearGradient(
                                colors: [.green, .blue],
                                startPoint: .leading,
                                endPoint: .trailing
                            )
                        )
                        .cornerRadius(15)
                    }
                    #endif
                }
                .padding(.horizontal, 40)
                
                Spacer()
            }
            .padding()
            .navigationBarHidden(true)
            .sheet(isPresented: $showSettings) {
                SettingsView(categoryManager: categoryManager)
            }
            .sheet(isPresented: $showAppSettings) {
                AppSettingsView()
            }
            .sheet(isPresented: $showCategoryManagement) {
                CategoryManagementView(categoryManager: categoryManager)
            }
            .fullScreenCover(isPresented: $showGame) {
                // KORRIGIERT: TimesUpGameView statt GameView
                TimesUpGameView(gameManager: devGameManager)
            }
        }
    }
}

#Preview {
    MainMenuView(categoryManager: CategoryManager())
}
