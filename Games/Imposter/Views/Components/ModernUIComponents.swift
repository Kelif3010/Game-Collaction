//
//  ModernUIComponents.swift
//  Imposter
//
//  Created by Ken on 22.09.25.
//

import SwiftUI

// MARK: - Section Header
struct SectionHeader: View {
    let title: String
    let icon: String
    
    var body: some View {
        HStack {
            Image(systemName: icon)
                .font(.title2)
                .foregroundColor(.orange)
            
            Text(title)
                .font(.title2)
                .fontWeight(.bold)
                .foregroundColor(.primary)
            
            Spacer()
        }
        .padding(.horizontal, 5)
    }
}

// MARK: - Modern Text Field Style
struct ModernTextFieldStyle: TextFieldStyle {
    @Environment(\.colorScheme) var colorScheme
    
    func _body(configuration: TextField<Self._Label>) -> some View {
        configuration
            .padding(.horizontal, 16)
            .padding(.vertical, 12)
            .background(colorScheme == .dark ? Color(.systemGray5) : Color(.systemGray6))
            .cornerRadius(12)
            .overlay(
                RoundedRectangle(cornerRadius: 12)
                    .stroke(Color.orange.opacity(0.3), lineWidth: 1)
            )
            .shadow(color: .black.opacity(colorScheme == .dark ? 0.2 : 0.1), radius: 2, x: 0, y: 1)
    }
}

// MARK: - Modern Player Card
struct ModernPlayerCard: View {
    let player: Player
    let onDelete: () -> Void
    @Environment(\.colorScheme) var colorScheme
    
    var body: some View {
        HStack {
            Image(systemName: "person.circle.fill")
                .font(.title2)
                .foregroundColor(.blue)
            
            Text(player.name)
                .font(.subheadline)
                .fontWeight(.medium)
                .lineLimit(1)
            
            Spacer()
            
            Button(action: onDelete) {
                Image(systemName: "xmark.circle.fill")
                    .foregroundColor(.red)
                    .font(.title3)
            }
        }
        .padding(.horizontal, 16)
        .padding(.vertical, 12)
        .background(
            RoundedRectangle(cornerRadius: 12)
                .fill(colorScheme == .dark ? Color(.systemGray6) : Color.white)
                .shadow(color: .black.opacity(colorScheme == .dark ? 0.2 : 0.1), radius: 3, x: 0, y: 2)
        )
        .overlay(
            RoundedRectangle(cornerRadius: 12)
                .stroke(Color.gray.opacity(colorScheme == .dark ? 0.3 : 0.2), lineWidth: 1)
        )
    }
}

// MARK: - Info Card
struct InfoCard: View {
    let text: String
    let icon: String
    
    var body: some View {
        HStack {
            Image(systemName: icon)
                .font(.title2)
                .foregroundColor(.blue)
            
            Text(text)
                .font(.subheadline)
                .foregroundColor(.secondary)
            
            Spacer()
        }
        .padding(.horizontal, 16)
        .padding(.vertical, 12)
        .background(
            RoundedRectangle(cornerRadius: 12)
                .fill(Color.blue.opacity(0.1))
        )
        .overlay(
            RoundedRectangle(cornerRadius: 12)
                .stroke(Color.blue.opacity(0.3), lineWidth: 1)
        )
    }
}

// MARK: - Setting Card
struct SettingCard<Content: View>: View {
    let content: Content
    @Environment(\.colorScheme) var colorScheme
    
    init(@ViewBuilder content: () -> Content) {
        self.content = content()
    }
    
    var body: some View {
        content
            .padding(.horizontal, 18)
            .padding(.vertical, 16)
            .background(
                RoundedRectangle(cornerRadius: 15)
                    .fill(colorScheme == .dark ? Color(.systemGray6) : Color.white)
                    .shadow(color: .black.opacity(colorScheme == .dark ? 0.3 : 0.1), radius: 5, x: 0, y: 3)
            )
            .overlay(
                RoundedRectangle(cornerRadius: 15)
                    .stroke(Color.gray.opacity(colorScheme == .dark ? 0.3 : 0.15), lineWidth: 1)
            )
    }
}

// MARK: - Game Action Button
struct GameActionButton: View {
    let title: String
    let icon: String
    let isEnabled: Bool
    
    var body: some View {
        HStack {
            Image(systemName: icon)
                .font(.title2)
                .foregroundColor(.white)
            
            Text(title)
                .font(.headline)
                .fontWeight(.semibold)
                .foregroundColor(.white)
            
            Spacer()
        }
        .padding(.horizontal, 25)
        .padding(.vertical, 18)
        .background(
            RoundedRectangle(cornerRadius: 15)
                .fill(LinearGradient(
                    colors: isEnabled ? [Color.orange, Color.red] : [Color.gray, Color.gray],
                    startPoint: .leading,
                    endPoint: .trailing
                ))
                .shadow(color: .black.opacity(isEnabled ? 0.3 : 0.1), radius: 5, x: 0, y: 3)
        )
    }
}

// MARK: - Category Card
struct ImposterCategoryCard: View {
    let category: Category
    let onTap: () -> Void
    @Environment(\.colorScheme) var colorScheme
    
    var body: some View {
        Button(action: onTap) {
            VStack(alignment: .leading, spacing: 12) {
                HStack {
                    Text(category.emoji)
                        .font(.title)
                    
                    Spacer()
                    
                    if category.isCustom {
                        Text("Eigene")
                            .font(.caption)
                            .padding(.horizontal, 8)
                            .padding(.vertical, 4)
                            .background(Color.purple.opacity(0.2))
                            .cornerRadius(8)
                            .foregroundColor(.purple)
                    }
                }
                
                Text(category.name)
                    .font(.headline)
                    .fontWeight(.semibold)
                    .foregroundColor(.primary)
                    .multilineTextAlignment(.leading)
                
                Text("\(category.words.count) Begriffe")
                    .font(.subheadline)
                    .foregroundColor(.secondary)
                
                Spacer()
            }
            .padding(.horizontal, 18)
            .padding(.vertical, 16)
            .frame(minHeight: 120)
            .background(
                RoundedRectangle(cornerRadius: 15)
                    .fill(colorScheme == .dark ? Color(.systemGray6) : Color.white)
                    .shadow(color: .black.opacity(colorScheme == .dark ? 0.3 : 0.1), radius: 5, x: 0, y: 3)
            )
            .overlay(
                RoundedRectangle(cornerRadius: 15)
                    .stroke(Color.gray.opacity(colorScheme == .dark ? 0.3 : 0.15), lineWidth: 1)
            )
        }
        .buttonStyle(PlainButtonStyle())
    }
}

// MARK: - Category Detail Card
struct CategoryDetailCard: View {
    let category: Category
    let onEdit: () -> Void
    let onDelete: () -> Void
    @Environment(\.colorScheme) var colorScheme
    
    var body: some View {
        VStack(alignment: .leading, spacing: 15) {
            // Header
            HStack {
                Text(category.emoji)
                    .font(.largeTitle)
                
                VStack(alignment: .leading, spacing: 2) {
                    Text(category.name)
                        .font(.title2)
                        .fontWeight(.bold)
                        .foregroundColor(.primary)
                    
                    Text("\(category.words.count) Begriffe")
                        .font(.subheadline)
                        .foregroundColor(.secondary)
                }
                
                Spacer()
                
                VStack(spacing: 8) {
                    Button(action: onEdit) {
                        Image(systemName: "pencil.circle.fill")
                            .font(.title2)
                            .foregroundColor(.blue)
                    }
                    
                    if category.isCustom {
                        Button(action: onDelete) {
                            Image(systemName: "trash.circle.fill")
                                .font(.title2)
                                .foregroundColor(.red)
                        }
                    }
                }
            }
            
            // Wörter-Grid
            LazyVGrid(columns: [
                GridItem(.adaptive(minimum: 100), spacing: 8)
            ], spacing: 8) {
                ForEach(category.words, id: \.self) { word in
                    Text(word)
                        .font(.caption)
                        .padding(.horizontal, 10)
                        .padding(.vertical, 6)
                        .background(Color.blue.opacity(0.1))
                        .cornerRadius(8)
                        .foregroundColor(.primary)
                }
            }
        }
        .padding(.horizontal, 18)
        .padding(.vertical, 16)
        .background(
            RoundedRectangle(cornerRadius: 15)
                .fill(colorScheme == .dark ? Color(.systemGray6) : Color.white)
                .shadow(color: .black.opacity(colorScheme == .dark ? 0.3 : 0.1), radius: 5, x: 0, y: 3)
        )
        .overlay(
            RoundedRectangle(cornerRadius: 15)
                .stroke(Color.gray.opacity(colorScheme == .dark ? 0.3 : 0.15), lineWidth: 1)
        )
    }
}
