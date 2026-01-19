//
//  QuestionsTheme.swift
//  Question
//
//  Created by Ken  on 27.12.25.
//

import SwiftUI

// MARK: - Design Theme
enum QuestionsTheme {
    static let gradient = LinearGradient(
        colors: [
            Color(red: 0.12, green: 0.02, blue: 0.18),
            Color(red: 0.5, green: 0.0, blue: 0.25),
            Color(red: 0.75, green: 0.0, blue: 0.23)
        ],
        startPoint: .topLeading,
        endPoint: .bottomTrailing
    )
    static let accent = Color.white
    static let textAccent = Color(red: 0.22, green: 0.02, blue: 0.14)
}

// MARK: - Shared Style Constants
enum QuestionsStyle {
    static let backgroundGradient = QuestionsTheme.gradient
    
    static let containerBackground = Color.black.opacity(0.25)
    static let rowBackground = Color.black.opacity(0.25)
    static let cardStroke = Color.white.opacity(0.08)
    static let containerCornerRadius: CGFloat = 22
    static let rowCornerRadius: CGFloat = 18
    static let padding: CGFloat = 20
    static let mutedText = Color.white.opacity(0.7)
    
    static let primaryGradient = LinearGradient(
        colors: [Color(red: 1.0, green: 0.41, blue: 0.23), Color(red: 0.94, green: 0.16, blue: 0.47)],
        startPoint: .topLeading,
        endPoint: .bottomTrailing
    )
    
    static let buttonGradient = LinearGradient(
         colors: [Color(red: 0.99, green: 0.35, blue: 0.38), Color(red: 0.78, green: 0.12, blue: 0.42)],
         startPoint: .topLeading,
         endPoint: .bottomTrailing
    )
}