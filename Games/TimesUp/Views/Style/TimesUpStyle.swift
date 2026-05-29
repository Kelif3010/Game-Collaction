//
//  TimesUpStyle.swift
//  Games Collection
//
//  Zentrale Design-Definitionen für TimesUp
//

import SwiftUI
import UIKit

// MARK: - TimesUp Design System

enum TimesUpStyle {

    // MARK: - Primary Theme Colors

    /// Primäre Akzentfarbe (Blau)
    static let primaryBlue = Color.blue

    /// Sekundäre Akzentfarbe (Violett)
    static let primaryPurple = Color.purple

    /// Erfolgsfarbe (Grün)
    static let successGreen = Color.green

    /// Warnfarbe (Orange)
    static let warningOrange = Color.orange

    /// Fehlerfarbe (Rot)
    static let errorRed = Color.red

    // MARK: - Gradients

    /// Haupt-Hintergrund-Gradient (Dark mit Blau/Violett-Akzenten)
    static let backgroundGradient = LinearGradient(
        colors: [
            Color.black,
            Color(.systemGray6).opacity(0.3),
            Color.blue.opacity(0.15),
            Color.purple.opacity(0.1)
        ],
        startPoint: .topLeading,
        endPoint: .bottomTrailing
    )

    /// Primärer Akzent-Gradient (Blau → Violett)
    static let primaryGradient = LinearGradient(
        colors: [.blue, .purple],
        startPoint: .leading,
        endPoint: .trailing
    )

    /// Erfolgs-Gradient (Grün)
    static let successGradient = LinearGradient(
        colors: [.green, .green.opacity(0.75)],
        startPoint: .topLeading,
        endPoint: .bottomTrailing
    )

    /// Start-Button Gradient (Grün → Blau)
    static let startButtonGradient = LinearGradient(
        colors: [.green, .blue],
        startPoint: .leading,
        endPoint: .trailing
    )

    /// Fehler-Gradient (Rot)
    static let errorGradient = LinearGradient(
        colors: [.red, .red.opacity(0.8)],
        startPoint: .topLeading,
        endPoint: .bottomTrailing
    )

    /// Streak-Gradient (Orange → Pink)
    static let streakGradient = LinearGradient(
        colors: [.orange, .pink],
        startPoint: .leading,
        endPoint: .trailing
    )

    /// Remaining-Terms Badge Gradient (Orange → Rot)
    static let termsBadgeGradient = LinearGradient(
        colors: [.orange, .red],
        startPoint: .topLeading,
        endPoint: .bottomTrailing
    )

    // MARK: - Layout Constants

    /// Container Eckenradius (Cards, große Container)
    static let containerCornerRadius: CGFloat = 22

    /// Zeilen/Buttons Eckenradius
    static let rowCornerRadius: CGFloat = 18

    /// Kleine Elemente Eckenradius
    static let smallCornerRadius: CGFloat = 14

    /// Icon-Badge Eckenradius
    static let iconCornerRadius: CGFloat = 12

    /// Standard horizontales Padding
    static let horizontalPadding: CGFloat = 20

    /// Standard vertikales Padding
    static let verticalPadding: CGFloat = 16

    /// Button vertikales Padding
    static let buttonVerticalPadding: CGFloat = 18

    /// Abstand vom unteren Bildschirmrand (für floating buttons)
    static let bottomPadding: CGFloat = 32

    // MARK: - Card & Container Styles

    /// Dunkler Karten-Hintergrund
    static let cardBackground = Color.black.opacity(0.4)

    /// Container-Hintergrund
    static let containerBackground = Color.black.opacity(0.25)

    /// Karten-Rand
    static let cardStroke = Color.white.opacity(0.1)

    /// Container-Rand
    static let containerStroke = Color.white.opacity(0.08)

    // MARK: - Text Colors

    /// Gedämpfter Text
    static let mutedText = Color.white.opacity(0.6)

    /// Sekundärer Text
    static let secondaryText = Color.white.opacity(0.7)

    // MARK: - Button Sizes

    /// Großer Action-Button (Correct)
    static let largeButtonSize: CGFloat = 120

    /// Standard Action-Button (Skip, Wrong)
    static let standardButtonSize: CGFloat = 80

    /// Icon-Button Größe (Header) – min. 44pt für HIG-konformes Touch-Target
    static let iconButtonSize: CGFloat = 44

    // MARK: - Shadows

    /// Standard Schatten-Farbe
    static func shadowColor(_ color: Color, opacity: Double = 0.4) -> Color {
        color.opacity(opacity)
    }

    /// Standard Schatten-Radius
    static let shadowRadius: CGFloat = 10

    /// Großer Schatten-Radius
    static let largeShadowRadius: CGFloat = 15
}

// MARK: - Reusable Components

/// Primärer Button im TimesUp-Stil
struct TimesUpPrimaryButton: View {
    let title: LocalizedStringKey
    let action: () -> Void
    var isDisabled: Bool = false

    var body: some View {
        Button(action: action) {
            Text(title)
                .font(.headline.weight(.bold))
                .foregroundStyle(.white)
                .frame(maxWidth: .infinity)
                .padding(.vertical, TimesUpStyle.buttonVerticalPadding)
                .background(
                    isDisabled
                    ? AnyShapeStyle(Color.gray.opacity(0.3))
                    : AnyShapeStyle(TimesUpStyle.startButtonGradient)
                )
                .clipShape(Capsule())
                .shadow(
                    color: isDisabled ? .clear : TimesUpStyle.shadowColor(.green),
                    radius: TimesUpStyle.shadowRadius,
                    x: 0,
                    y: 5
                )
        }
        .disabled(isDisabled)
        .opacity(isDisabled ? 0.6 : 1.0)
    }
}

/// Icon-Badge für Settings-Rows
struct TimesUpIconBadge: View {
    let systemName: String
    var gradient: LinearGradient = TimesUpStyle.primaryGradient

    var body: some View {
        ZStack {
            RoundedRectangle(cornerRadius: TimesUpStyle.iconCornerRadius)
                .fill(gradient.opacity(0.3))
                .frame(width: 44, height: 44)

            Image(systemName: systemName)
                .foregroundStyle(.white)
                .font(.headline)
        }
    }
}

/// Standard-Header für TimesUp Views
struct TimesUpSheetHeader: View {
    let title: LocalizedStringKey
    let onBack: () -> Void

    var body: some View {
        HStack {
            Button(action: onBack) {
                Image(systemName: "chevron.left")
                    .font(.headline.bold())
                    .foregroundStyle(.white)
                    .frame(width: TimesUpStyle.iconButtonSize, height: TimesUpStyle.iconButtonSize)
                    .modifier(GlassCircleButtonBackground())
            }

            Spacer()

            Text(title)
                .font(.title3.bold())
                .foregroundStyle(.white)

            Spacer()

            Color.clear
                .frame(width: TimesUpStyle.iconButtonSize, height: TimesUpStyle.iconButtonSize)
        }
        .padding(.top, TimesUpStyle.horizontalPadding)
        .padding(.bottom, 8)
    }
}

/// Zeilen-Stil Modifier für TimesUp
struct TimesUpRowStyle: ViewModifier {
    func body(content: Content) -> some View {
        content
            .padding(.horizontal, 14)
            .padding(.vertical, 12)
            .background(
                RoundedRectangle(cornerRadius: TimesUpStyle.rowCornerRadius, style: .continuous)
                    .fill(TimesUpStyle.cardBackground)
            )
            .overlay(
                RoundedRectangle(cornerRadius: TimesUpStyle.rowCornerRadius, style: .continuous)
                    .stroke(TimesUpStyle.cardStroke, lineWidth: 1)
            )
    }
}

/// Container-Stil Modifier für TimesUp
struct TimesUpContainerStyle: ViewModifier {
    func body(content: Content) -> some View {
        content
            .padding()
            .background(TimesUpStyle.containerBackground)
            .clipShape(RoundedRectangle(cornerRadius: TimesUpStyle.containerCornerRadius))
            .overlay(
                RoundedRectangle(cornerRadius: TimesUpStyle.containerCornerRadius)
                    .stroke(TimesUpStyle.containerStroke, lineWidth: 1)
            )
    }
}

// MARK: - View Extensions

extension View {
    /// Wendet den TimesUp-Zeilen-Stil an
    func timesUpRowStyle() -> some View {
        modifier(TimesUpRowStyle())
    }

    /// Wendet den TimesUp-Container-Stil an
    func timesUpContainerStyle() -> some View {
        modifier(TimesUpContainerStyle())
    }

    /// Standard TimesUp Hintergrund
    func timesUpBackground() -> some View {
        self.background(TimesUpStyle.backgroundGradient.ignoresSafeArea())
    }
}

// MARK: - Haptics Helper

enum TimesUpHaptics {
    static func impact(_ style: UIImpactFeedbackGenerator.FeedbackStyle = .light) {
        UIImpactFeedbackGenerator(style: style).impactOccurred()
    }

    static func selection() {
        UISelectionFeedbackGenerator().selectionChanged()
    }

    static func notification(_ type: UINotificationFeedbackGenerator.FeedbackType) {
        UINotificationFeedbackGenerator().notificationOccurred(type)
    }
}
