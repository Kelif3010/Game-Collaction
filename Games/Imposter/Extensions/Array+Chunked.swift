//
//  Array+Chunked.swift
//  Imposter
//
//  Created by Ken on 23.09.25.
//

import Foundation

extension Array {
    /// Teilt das Array in Chunks der angegebenen Größe auf
    /// - Parameter size: Die maximale Größe jedes Chunks
    /// - Returns: Array von Arrays (Chunks)
    func chunked(into size: Int) -> [[Element]] {
        return stride(from: 0, to: count, by: size).map {
            Array(self[$0..<Swift.min($0 + size, count)])
        }
    }
}
