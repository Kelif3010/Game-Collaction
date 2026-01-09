//
//  LeaderboardView.swift
//  Imposter
//
//  Created by Ken on 25.09.25.
//

import SwiftUI

enum LeaderboardTab: String, CaseIterable {
    case overall = "Gesamt"
    case spies = "Top Spione"
    case citizens = "Top Bürger"
}

struct LeaderboardView: View {
    @StateObject private var statsService = StatsService.shared
    @Environment(\.dismiss) var dismiss
    @State private var selectedTab: LeaderboardTab = .overall
    @State private var showDeleteConfirmation = false
    
    var body: some View {
        ZStack {
            ImposterStyle.backgroundGradient.ignoresSafeArea()
            
            VStack(spacing: 0) {
                // Header
                HStack {
                    Button(action: { dismiss() }) {
                        Image(systemName: "chevron.left")
                            .font(.headline.bold())
                            .foregroundColor(.white)
                            .padding(10)
                            .background(Color.white.opacity(0.1))
                            .clipShape(Circle())
                    }
                    
                    Spacer()
                    
                    Text("RANGLISTE")
                        .font(.headline.bold())
                        .tracking(2)
                        .foregroundColor(.white)
                    
                    Spacer()
                    
                    Button(action: { showDeleteConfirmation = true }) {
                        Image(systemName: "trash")
                            .font(.headline)
                            .foregroundColor(.white.opacity(0.6))
                            .padding(10)
                    }
                }
                .padding()
                
                // Tab Switcher
                HStack(spacing: 4) {
                    ForEach(LeaderboardTab.allCases, id: \.self) { tab in
                        Button(action: {
                            withAnimation(.spring(response: 0.3)) {
                                selectedTab = tab
                            }
                        }) {
                            Text(tab.rawValue)
                                .font(.subheadline.bold())
                                .foregroundColor(selectedTab == tab ? .white : .white.opacity(0.6))
                                .padding(.vertical, 8)
                                .frame(maxWidth: .infinity)
                                .background(
                                    RoundedRectangle(cornerRadius: 8)
                                        .fill(selectedTab == tab ? Color.white.opacity(0.15) : Color.clear)
                                )
                        }
                    }
                }
                .padding(4)
                .background(Color.black.opacity(0.2))
                .cornerRadius(12)
                .padding(.horizontal)
                .padding(.bottom, 10)
                
                // Content
                ScrollView {
                    LazyVStack(spacing: 12) {
                        let entries = sortedEntries(for: selectedTab)
                        
                        if entries.isEmpty {
                            EmptyStateView()
                                .padding(.top, 50)
                        } else {
                            // Top 3 Podium (optional, if enough players)
                            if entries.count >= 3 && selectedTab == .overall {
                                PodiumView(first: entries[0], second: entries[1], third: entries[2])
                                    .padding(.bottom, 20)
                            }
                            
                            // List
                            ForEach(Array(entries.enumerated()), id: \.element.id) { index, stat in
                                if selectedTab == .overall && index < 3 && entries.count >= 3 {
                                    // Skip podium players in list if shown in podium
                                } else {
                                    RankRow(
                                        rank: index + 1,
                                        stat: stat,
                                        type: selectedTab
                                    )
                                    .transition(.opacity.combined(with: .slide))
                                }
                            }
                        }
                    }
                    .padding()
                    .padding(.bottom, 40)
                }
            }
        }
        .alert("Rangliste zurücksetzen?", isPresented: $showDeleteConfirmation) {
            Button("Abbrechen", role: .cancel) { }
            Button("Löschen", role: .destructive) {
                statsService.resetAllStats()
            }
        } message: {
            Text("Alle gesammelten Punkte und Statistiken werden unwiderruflich gelöscht.")
        }
    }
    
    private func sortedEntries(for tab: LeaderboardTab) -> [PlayerStats] {
        let all = statsService.getAllStats()
        switch tab {
        case .overall:
            return all.sorted { $0.totalPoints > $1.totalPoints }
        case .spies:
            return all.sorted { $0.imposterWins > $1.imposterWins }
        case .citizens:
            return all.sorted { $0.citizenWins > $1.citizenWins }
        }
    }
}

// MARK: - Subviews

struct RankRow: View {
    let rank: Int
    let stat: PlayerStats
    let type: LeaderboardTab
    
    var body: some View {
        HStack(spacing: 16) {
            // Rank Number
            Text("\(rank)")
                .font(.title3.bold())
                .foregroundColor(.white.opacity(0.5))
                .frame(width: 30)
            
            // Name & Detail
            VStack(alignment: .leading, spacing: 4) {
                Text(stat.playerName)
                    .font(.headline)
                    .foregroundColor(.white)
                
                Group {
                    switch type {
                    case .overall:
                        Text("\(stat.totalGames) Spiele • \(Int(stat.winRateAsImposter * 100))% Spion-Siegquote")
                    case .spies:
                        Text("\(stat.imposterGames) Einsätze • \(stat.wordsGuessedCorrectly) Worte erraten")
                    case .citizens:
                        Text("\(stat.citizenGames) Einsätze • \(stat.citizenWins) Siege")
                    }
                }
                .font(.caption)
                .foregroundColor(.white.opacity(0.6))
            }
            
            Spacer()
            
            // Main Value
            VStack(alignment: .trailing) {
                switch type {
                case .overall:
                    Text("\(stat.totalPoints)")
                        .font(.title3.bold())
                        .foregroundColor(.orange)
                    Text("PKT")
                        .font(.system(size: 8, weight: .bold))
                        .foregroundColor(.orange.opacity(0.7))
                case .spies:
                    Text("\(stat.imposterWins)")
                        .font(.title3.bold())
                        .foregroundColor(.red)
                    Text("SIEGE")
                        .font(.system(size: 8, weight: .bold))
                        .foregroundColor(.red.opacity(0.7))
                case .citizens:
                    Text("\(stat.citizenWins)")
                        .font(.title3.bold())
                        .foregroundColor(.green)
                    Text("SIEGE")
                        .font(.system(size: 8, weight: .bold))
                        .foregroundColor(.green.opacity(0.7))
                }
            }
        }
        .padding()
        .background(Color.white.opacity(0.05))
        .cornerRadius(16)
        .overlay(
            RoundedRectangle(cornerRadius: 16)
                .stroke(Color.white.opacity(0.1), lineWidth: 1)
        )
    }
}

struct PodiumView: View {
    let first: PlayerStats
    let second: PlayerStats
    let third: PlayerStats
    
    var body: some View {
        HStack(alignment: .bottom, spacing: 12) {
            PodiumColumn(stat: second, rank: 2, color: Color(white: 0.8))
            PodiumColumn(stat: first, rank: 1, color: .yellow)
            PodiumColumn(stat: third, rank: 3, color: Color(red: 0.8, green: 0.5, blue: 0.2))
        }
        .padding(.top, 20)
    }
}

struct PodiumColumn: View {
    let stat: PlayerStats
    let rank: Int
    let color: Color
    
    var height: CGFloat {
        switch rank {
        case 1: return 140
        case 2: return 110
        default: return 90
        }
    }
    
    var body: some View {
        VStack {
            Text(stat.playerName)
                .font(.caption.bold())
                .lineLimit(1)
                .foregroundColor(.white)
                .padding(.bottom, 4)
            
            ZStack(alignment: .bottom) {
                RoundedRectangle(cornerRadius: 12, style: .continuous)
                    .fill(
                        LinearGradient(
                            colors: [color.opacity(0.6), color.opacity(0.2)],
                            startPoint: .top,
                            endPoint: .bottom
                        )
                    )
                    .frame(height: height)
                    .overlay(
                        RoundedRectangle(cornerRadius: 12)
                            .stroke(color.opacity(0.5), lineWidth: 1)
                    )
                
                VStack(spacing: 2) {
                    Text("\(rank)")
                        .font(.title.bold())
                        .foregroundColor(.white)
                    
                    Text("\(stat.totalPoints)")
                        .font(.caption.bold())
                        .foregroundColor(.white.opacity(0.8))
                }
                .padding(.bottom, 12)
            }
        }
        .frame(maxWidth: .infinity)
    }
}

struct EmptyStateView: View {
    var body: some View {
        VStack(spacing: 16) {
            Image(systemName: "trophy")
                .font(.system(size: 50))
                .foregroundColor(.white.opacity(0.2))
            
            Text("Keine Daten vorhanden")
                .font(.headline)
                .foregroundColor(.white.opacity(0.5))
            
            Text("Spiele eine Runde, um Punkte zu sammeln!")
                .font(.caption)
                .foregroundColor(.white.opacity(0.3))
        }
    }
}
