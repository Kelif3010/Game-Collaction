//
//  AIModels.swift
//  Imposter
//
//  Created by Ken on 30.09.25.
//

import Foundation

#if canImport(FoundationModels)
import FoundationModels

@available(iOS 26.0, *)
@Generable(description: "Structured game content for a spy party game")
struct AIGeneratedGameContent {
    @Guide(description: "The content type: hint, fake_hint, or challenge")
    var type: String

    @Guide(description: "A short German clue or challenge")
    var content: String

    @Guide(description: "Whether the clue is factually true for the secret word")
    var isTrue: Bool
}

@available(iOS 26.0, *)
@Generable(description: "A list of vague spy hints in German")
struct AISpyHintsResponse {
    @Guide(description: "Short vague German hints that all begin with Es")
    var hints: [String]
}

@available(iOS 26.0, *)
@Generable(description: "A list of role names for a location-based spy game")
struct AIRoleListResponse {
    @Guide(description: "Distinct German role names")
    var roles: [String]
}

@available(iOS 26.0, *)
@Generable(description: "Eine kurze Mission-Beschreibung für einen Spion")
struct MissionFlavor {
    @Guide(description: "Ein spannender Satz auf Deutsch, maximal 80 Zeichen, geheimnisvoller Ton")
    var text: String
}

@available(iOS 26.0, *)
@Generable(description: "Ein kurzes Moderator-Log zur Imposter-Auswahl")
struct ModeratorLogEntry {
    @Guide(description: "Technische Erklärung der Auswahl in 1-2 Sätzen auf Deutsch")
    var text: String
}

@available(iOS 26.0, *)
@Generable(description: "Eine typische Rolle für einen bestimmten Ort")
struct LocationRole {
    @Guide(description: "Eine einzelne deutsche Rollenbezeichnung wie 'Koch', 'Wachmann' oder 'Arzt'")
    var role: String
}
#endif

// JSON-Strukturen für KI-Antworten (Guided via Prompt-Constraints)

struct AIHintDTO: Codable {
    let content: String
    let isTrue: Bool
    let type: String           // "general" | "letter" | "length" | "category" | "rhyme" | "type"
}
