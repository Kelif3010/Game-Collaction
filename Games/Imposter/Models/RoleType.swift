//
//  RoleType.swift
//  Imposter
//
//  Created by Ken on 06.01.2026.
//

import Foundation

enum RoleTeam: String, Codable {
    case citizen = "Team Bürger"
    case imposter = "Team Spion"
    case neutral = "Team Chaos"
}

enum RoleType: String, CaseIterable, Codable, Identifiable {
    case secretAgent = "Geheimagent"
    case twins = "Zwillinge"
    case bodyguard = "Leibwächter"
    case saboteur = "Saboteur"
    case hacker = "Hacker"
    case mole = "Maulwurf"
    case fool = "Narr"
    case confused = "Pechvogel"
    
    var id: String { rawValue }
    
    var team: RoleTeam {
        switch self {
        case .secretAgent, .twins, .bodyguard:
            return .citizen
        case .saboteur, .hacker, .mole:
            return .imposter
        case .fool, .confused:
            return .neutral
        }
    }
    
    var description: String {
        switch self {
        case .secretAgent:
            return "Kennt das Wort und sieht, wer der Spion ist. Muss sich bedeckt halten."
        case .twins:
            return "Kennen das Wort und sehen ihren Zwilling. Vertrauen sich blind."
        case .bodyguard:
            return "Kennt das Wort. Wählt jemanden aus, den er vor dem Voting oder Attentat schützt."
        case .saboteur:
            return "Kennt das Wort und den Spion. Hilft dem Spion durch Verwirrung."
        case .hacker:
            return "Kennt das Wort NICHT. Darf beim Start einen Spieler scannen und dessen Rolle sehen."
        case .mole:
            return "Kennt das Wort. Erscheint für den Geheimagenten fälschlicherweise als Spion."
        case .fool:
            return "Kennt das Wort. Gewinnt nur, wenn er von der Gruppe rausgewählt wird."
        case .confused:
            return "Sieht ein falsches Wort aus der gleichen Kategorie. Denkt, er sei Bürger."
        }
    }
    
    var icon: String {
        switch self {
        case .secretAgent: return "eye.circle.fill"
        case .twins: return "person.2.circle.fill"
        case .bodyguard: return "shield.fill"
        case .saboteur: return "hammer.fill"
        case .hacker: return "terminal.fill"
        case .mole: return "ant.fill"
        case .fool: return "theatermasks.circle.fill"
        case .confused: return "questionmark.circle.fill"
        }
    }
    
    // MARK: - Card Display Properties
    
    var cardTitle: String {
        self.rawValue.uppercased()
    }
    
    var cardIcon: String {
        self.icon
    }
    
    var cardColorName: String {
        switch team {
        case .citizen: return "darkBlue"
        case .imposter: return "darkRed"
        case .neutral: return "darkPurple"
        }
    }
    
    var shortInstruction: String {
        switch self {
        case .secretAgent: return "Führe die Bürger zum Spion, aber bleib verdeckt."
        case .twins: return "Arbeite mit deinem Zwilling zusammen. Ihr seid sicher."
        case .bodyguard: return "Wähle jemanden zum Beschützen aus."
        case .saboteur: return "Verwirre die Bürger und beschütze deinen Spion."
        case .hacker: return "Hacke einen Spieler, um seine Identität zu stehlen."
        case .mole: return "Täusche den Geheimagenten – du wirkst wie der Spion."
        case .fool: return "Verhalte dich so verdächtig, dass man dich rauswählt."
        case .confused: return "Beschreibe dein Wort und finde den Spion (Vorsicht!)."
        }
    }
}