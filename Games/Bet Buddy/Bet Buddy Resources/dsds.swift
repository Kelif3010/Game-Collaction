import Foundation

extension Int {
    /// Wandelt eine Zahl in einen Buchstaben um (1 = A, 2 = B, ..., 26 = Z, 27 = AA...)
    var asAlphabet: String {
        // KORREKTUR: Swift.max verwenden, da "max" sonst mit Int.max verwechselt wird
        let value = Swift.max(0, self)
        if value == 0 { return "-" } // 0 ist kein Buchstabe
        
        let alphabet = "ABCDEFGHIJKLMNOPQRSTUVWXYZ"
        let count = alphabet.count
        var result = ""
        var number = value - 1 // 0-basiert arbeiten
        
        repeat {
            let remainder = number % count
            let charIndex = alphabet.index(alphabet.startIndex, offsetBy: remainder)
            result.insert(alphabet[charIndex], at: result.startIndex)
            number = number / count - 1
        } while number >= 0
        
        return result
    }
}
