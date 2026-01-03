//
//  AIModels.swift
//  Imposter
//
//  Created by Ken on 30.09.25.
//

import Foundation

// JSON-Strukturen für KI-Antworten (Guided via Prompt-Constraints)

struct AIHintDTO: Codable {
    let content: String
    let isTrue: Bool
    let type: String           // "general" | "letter" | "length" | "category" | "rhyme" | "type"
}


