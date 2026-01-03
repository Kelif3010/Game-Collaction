//
//  PerkType.swift
//  TimesUp
//
//  Created by Ken on 23.09.25.
//

import Foundation

enum PerkType: String, CaseIterable, Identifiable, Codable {
    case freezeTime
    case slowMotionOpponent
    case rewindHit
    case timeBomb
    case nextWordDouble
    case doublePointsThisTurn
    case stealPoints
    case shield
    case comboBonus
    case assistPoints
    case mirroredWord
    case forcedSkip
    case freezeSkipButton
    case glitchLetters
    case pausePenalty
    case swapWord
    case suddenRush
    case invisibleWord
    case englishWord
    
    var id: String { rawValue }
    
    var pack: PerkPack {
        switch self {
        case .freezeTime, .slowMotionOpponent, .rewindHit, .timeBomb, .suddenRush:
            return .tempo
        case .nextWordDouble, .doublePointsThisTurn, .stealPoints, .shield, .comboBonus, .assistPoints:
            return .score
        case .mirroredWord, .forcedSkip, .freezeSkipButton, .glitchLetters, .pausePenalty, .swapWord, .invisibleWord, .englishWord:
            return .sabotage
        }
    }

    var displayName: String {
        switch self {
        case .freezeTime: return "Zeit einfrieren"
        case .slowMotionOpponent: return "Slow Motion Gegner"
        case .rewindHit: return "Zeit-Boost"
        case .timeBomb: return "Zeitbombe"
        case .suddenRush: return "Sudden Rush"
        case .nextWordDouble: return "Nächstes Wort x2"
        case .doublePointsThisTurn: return "Doppelte Punkte im Zug"
        case .stealPoints: return "Punkte stehlen"
        case .shield: return "Schutzschild"
        case .comboBonus: return "Combo Bonus"
        case .assistPoints: return "Assist Punkte"
        case .mirroredWord: return "Spiegelwort"
        case .forcedSkip: return "Zwangs-Skip"
        case .freezeSkipButton: return "Skip gesperrt"
        case .glitchLetters: return "Glitch-Buchstaben"
        case .pausePenalty: return "Zeitbremse"
        case .swapWord: return "Worttausch"
        case .invisibleWord: return "Unsichtbares Wort"
        case .englishWord: return "English Word"
        }
    }
    
    var detailDescription: String {
        switch self {
        case .freezeTime: return "Stoppt euren Timer für 5 Sekunden."
        case .slowMotionOpponent: return "Nimmt dem Gegner 5 Sekunden beim nächsten Start."
        case .rewindHit: return "+2 Sekunden auf den Timer nach jedem Treffer in diesem Zug."
        case .timeBomb: return "Gegner verliert alle 3 Sekunden 1 Sekunde, bis ein Treffer gelingt."
        case .suddenRush: return "Euer Timer läuft 10 Sekunden doppelt so schnell."
        case .nextWordDouble: return "Der nächste Begriff zählt doppelt."
        case .doublePointsThisTurn: return "Alle Treffer dieses Zuges geben doppelte Punkte."
        case .stealPoints: return "Stiehlt dem Gegner 2 Punkte und addiert sie zu euch."
        case .shield: return "Blockiert die nächste Zeit- oder Punktestrafe."
        case .comboBonus: return "+3 Punkte nach drei Treffern in Folge."
        case .assistPoints: return "+1 Punkt, wenn der Gegner als Nächstes skippt."
        case .mirroredWord: return "Der Gegner sieht sein Wort 5 Sekunden lang spiegelverkehrt."
        case .forcedSkip: return "Der Gegner muss den nächsten Begriff sofort skippen."
        case .freezeSkipButton: return "Sperrt den gegnerischen Skip-Button für 10 Sekunden."
        case .glitchLetters: return "Verstümmelt Buchstaben im gegnerischen Wort für 5 Sekunden."
        case .pausePenalty: return "-2 Sekunden für den Gegner, sobald er den nächsten Begriff löst."
        case .swapWord: return "Wechselt das aktuelle Gegnerwort nach 3 Sekunden zufällig."
        case .invisibleWord: return "Lässt das Wort 2 Sekunden nach Anzeige verschwinden."
        case .englishWord: return "Zeigt das Wort für 7 Sekunden auf Englisch an und verwirrt den Gegner."
        }
    }
    
    var isImplemented: Bool {
        switch self {
        case .freezeTime,
             .slowMotionOpponent,
             .rewindHit,
             .timeBomb,
             .suddenRush,
             .nextWordDouble,
             .doublePointsThisTurn,
             .stealPoints,
             .shield,
             .comboBonus,
             .assistPoints,
             .mirroredWord,
             .forcedSkip,
             .freezeSkipButton,
             .glitchLetters,
             .pausePenalty,
             .swapWord,
             .invisibleWord,
             .englishWord:
            return true
        }
    }
    
    static func random(from packs: Set<PerkPack>) -> PerkType? {
        let allowedPacks = packs.filter { !$0.isCustom }
        guard !allowedPacks.isEmpty else { return nil }
        let candidates = PerkType.allCases.filter {
            allowedPacks.contains($0.pack) && $0.isImplemented
        }
        return candidates.randomElement()
    }
}
