import Foundation

/// Wird von PartyHubView an jeden Game-Wrapper übergeben.
/// Enthält die im Party-Setup gewählten Spielernamen, damit jedes Spiel
/// diese automatisch vorausfüllen kann statt ein eigenes Setup zu verlangen.
struct PartyGameLaunchContext {
    let playerNames: [String]
}
