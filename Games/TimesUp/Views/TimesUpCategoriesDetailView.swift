//
//  TimesUpCategoriesDetailView.swift
//  TimesUp
//

import SwiftUI

struct CategoriesDetailView: View {
    @ObservedObject var gameManager: GameManager
    @Environment(\.dismiss) private var dismiss

    var body: some View {
        ZStack {
            TimesUpStyle.backgroundGradient.ignoresSafeArea()

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
                    Text(LocalizedStringKey("Kategorien"))
                        .font(.title2.bold())
                        .foregroundStyle(.white)
                    Spacer()
                    Text("\(gameManager.gameState.settings.selectedCategories.count)")
                        .font(.headline)
                        .foregroundStyle(.blue)
                        .padding(.horizontal, 12)
                        .padding(.vertical, 6)
                        .background(Color.blue.opacity(0.2))
                        .clipShape(Capsule())
                }
                .padding(.horizontal, TimesUpStyle.horizontalPadding)
                .padding(.top, 10)

                ScrollView {
                    VStack(spacing: 12) {
                        ForEach(gameManager.availableCategories) { category in
                            TimesUpCategoryRowView(
                                category: category,
                                isSelected: gameManager.gameState.settings.selectedCategories.contains(category)
                            )
                            .onTapGesture {
                                TimesUpHaptics.impact(.light)
                                gameManager.toggleCategory(category)
                            }
                        }
                    }
                    .padding(.horizontal, TimesUpStyle.horizontalPadding)
                    .padding(.bottom, 40)
                }
            }
        }
        .toolbar(.hidden, for: .navigationBar)
    }
}

// MARK: - Category Row

struct TimesUpCategoryRowView: View {
    let category: TimesUpCategory
    let isSelected: Bool

    var body: some View {
        HStack(alignment: .center, spacing: 14) {
            ZStack {
                RoundedRectangle(cornerRadius: 14)
                    .fill(
                        LinearGradient(
                            colors: [category.type.color.opacity(0.3), category.type.color.opacity(0.1)],
                            startPoint: .topLeading,
                            endPoint: .bottomTrailing
                        )
                    )
                    .frame(width: 48, height: 48)

                Image(systemName: category.type.systemImage)
                    .font(.title3.bold())
                    .foregroundStyle(category.type.color)
            }

            VStack(alignment: .leading, spacing: 4) {
                Text(LocalizedStringKey(category.name))
                    .foregroundStyle(.white)
                    .font(.headline)

                Text(LocalizedStringKey(category.type.rawValue))
                    .foregroundStyle(TimesUpStyle.mutedText)
                    .font(.caption)
            }

            Spacer()

            ZStack {
                if isSelected {
                    Circle()
                        .fill(category.type.color)
                        .frame(width: 24, height: 24)
                        .overlay(
                            Image(systemName: "checkmark")
                                .font(.caption.bold())
                                .foregroundStyle(.black)
                        )
                        .shadow(color: category.type.color.opacity(0.6), radius: 6, x: 0, y: 0)
                } else {
                    Circle()
                        .stroke(Color.white.opacity(0.2), lineWidth: 2)
                        .frame(width: 24, height: 24)
                }
            }
        }
        .padding()
        .background(
            ZStack {
                if isSelected {
                    RoundedRectangle(cornerRadius: 16)
                        .fill(category.type.color.opacity(0.15))
                } else {
                    RoundedRectangle(cornerRadius: 16)
                        .fill(Color.black.opacity(0.3))
                }
            }
        )
        .overlay(
            RoundedRectangle(cornerRadius: 16)
                .stroke(
                    isSelected ? category.type.color.opacity(0.6) : Color.white.opacity(0.05),
                    lineWidth: isSelected ? 1.5 : 1
                )
        )
        .shadow(color: isSelected ? category.type.color.opacity(0.15) : .clear, radius: 10, x: 0, y: 4)
        .clipShape(RoundedRectangle(cornerRadius: 16))
        .scaleEffect(isSelected ? 1.02 : 1.0)
        .animation(.spring(response: 0.3, dampingFraction: 0.6), value: isSelected)
    }
}
