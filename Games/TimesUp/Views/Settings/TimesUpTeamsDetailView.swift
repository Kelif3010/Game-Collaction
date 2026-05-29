//
//  TimesUpTeamsDetailView.swift
//  TimesUp
//

import SwiftUI

struct TeamsDetailView: View {
    @ObservedObject var viewModel: TimesUpGameViewModel
    @Environment(\.dismiss) private var dismiss
    @State private var newTeamName = ""

    var body: some View {
        ZStack {
            TimesUpStyle.backgroundGradient.ignoresSafeArea()

            ScrollView {
                VStack(spacing: 20) {
                    HStack {
                        Button { dismiss() } label: {
                            Image(systemName: "chevron.left")
                                .font(.title2.bold())
                                .foregroundStyle(.white)
                                .frame(width: 44, height: 44)
                                .modifier(GlassCircleButtonBackground())
                        }
                        Spacer()
                        Text("Teams")
                            .font(.title2.bold())
                            .foregroundStyle(.white)
                        Spacer()
                        Color.clear.frame(width: 44)
                    }
                    .padding(.top, 10)

                    VStack(spacing: 16) {
                        HStack(spacing: 12) {
                            TextField("", text: $newTeamName, prompt: Text(LocalizedStringKey("Teamname...")).foregroundStyle(.gray))
                                .padding()
                                .background(Color.white.opacity(0.1))
                                .clipShape(RoundedRectangle(cornerRadius: 14))
                                .foregroundStyle(.white)
                                .onSubmit(addTeamIfPossible)

                            Button(action: addTeamIfPossible) {
                                Image(systemName: "plus")
                                    .font(.title2.bold())
                                    .foregroundStyle(.white)
                                    .frame(width: 50, height: 50)
                                    .background(newTeamName.trimmingCharacters(in: .whitespaces).isEmpty ? Color.gray.opacity(0.3) : Color.blue)
                                    .clipShape(Circle())
                            }
                            .disabled(newTeamName.trimmingCharacters(in: .whitespaces).isEmpty)
                        }

                        if viewModel.gameState.settings.teams.count < 2 {
                            HStack(spacing: 6) {
                                Spacer()
                                Image(systemName: "exclamationmark.triangle.fill")
                                    .foregroundStyle(.orange)
                                Text(LocalizedStringKey("Mindestens 2 Teams erforderlich"))
                                    .font(.caption)
                                    .foregroundStyle(.orange)
                                Spacer()
                            }
                        }

                        VStack(spacing: 12) {
                            ForEach(viewModel.gameState.settings.teams) { team in
                                HStack {
                                    Circle()
                                        .fill(LinearGradient(colors: [.blue, .purple], startPoint: .topLeading, endPoint: .bottomTrailing))
                                        .frame(width: 40, height: 40)
                                        .overlay(
                                            Text(String(team.name.prefix(1)))
                                                .font(.headline.bold())
                                                .foregroundStyle(.white)
                                        )

                                    Text(team.name)
                                        .font(.body.weight(.medium))
                                        .foregroundStyle(.white)
                                        .padding(.leading, 8)

                                    Spacer()

                                    Button {
                                        withAnimation {
                                            viewModel.removeTeam(team)
                                        }
                                    } label: {
                                        Image(systemName: "trash")
                                            .foregroundStyle(.red.opacity(0.8))
                                            .padding(8)
                                    }
                                }
                                .padding()
                                .background(Color.white.opacity(0.08))
                                .clipShape(RoundedRectangle(cornerRadius: 18))
                                .scrollTransition { content, phase in
                                    content
                                        .opacity(phase.isIdentity ? 1 : 0.6)
                                        .offset(y: phase.isIdentity ? 0 : 12)
                                }
                            }
                        }
                    }
                }
            }
            .padding(.horizontal, TimesUpStyle.horizontalPadding)
            .padding(.bottom, 40)
        }
        .scrollDismissesKeyboard(.interactively)
        .toolbar(.hidden, for: .navigationBar)
    }

    private func addTeamIfPossible() {
        let name = newTeamName.trimmingCharacters(in: .whitespacesAndNewlines)
        guard !name.isEmpty else { return }
        withAnimation {
            viewModel.addTeam(name: name)
        }
        newTeamName = ""
    }
}
