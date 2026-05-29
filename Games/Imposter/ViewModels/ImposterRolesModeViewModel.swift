//
//  ImposterRolesModeViewModel.swift
//  Games Collection
//

import Foundation

@MainActor
@Observable
final class ImposterRolesModeViewModel {
    enum AssignmentError: LocalizedError {
        case aiUnavailable
        case generationFailed

        var errorDescription: String? {
            switch self {
            case .aiUnavailable:
                return "Rollen-Modus benötigt Apple Intelligence."
            case .generationFailed:
                return "KI konnte keine passenden Rollen für diesen Ort erzeugen."
            }
        }
    }

    private let aiService: AIService

    init(aiService: AIService = .shared) {
        self.aiService = aiService
    }

    var canGenerateRoles: Bool {
        aiService.isAvailable
    }

    func generateLocationRoles(for location: String, playerCount: Int) async throws -> [String] {
        guard aiService.isAvailable else {
            throw AssignmentError.aiUnavailable
        }

        guard let roles = await aiService.generateStrictLocationRoles(for: location, count: playerCount),
              roles.count == playerCount else {
            throw AssignmentError.generationFailed
        }
        return roles
    }
}
