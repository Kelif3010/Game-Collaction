import SwiftUI
import CoreImage.CIFilterBuiltins

final class QRCodeService {
    static let shared = QRCodeService()
    private let context = CIContext()
    private let filter = CIFilter.qrCodeGenerator()
    
    /// Generiert einen QR-Code aus einem String
    func generateQRCode(from string: String) -> UIImage? {
        let data = Data(string.utf8)
        filter.setValue(data, forKey: "inputMessage")
        filter.setValue("H", forKey: "inputCorrectionLevel") // High error correction

        if let outputImage = filter.outputImage {
            // Skalieren für scharfe Darstellung
            let transform = CGAffineTransform(scaleX: 10, y: 10)
            let scaledImage = outputImage.transformed(by: transform)
            
            if let cgImage = context.createCGImage(scaledImage, from: scaledImage.extent) {
                return UIImage(cgImage: cgImage)
            }
        }
        return nil
    }
    
    /// Wandelt ein beliebiges Codable Objekt in einen JSON-String um (komprimiert)
    func encodeForSharing<T: Codable>(_ object: T) -> String? {
        let encoder = JSONEncoder()
        encoder.outputFormatting = [] // Compact
        guard let data = try? encoder.encode(object) else { return nil }
        return String(data: data, encoding: .utf8)
    }
    
    /// Wandelt einen String zurück in ein Objekt
    func decodeFromSharing<T: Codable>(_ string: String, type: T.Type) -> T? {
        guard let data = string.data(using: .utf8) else { return nil }
        return try? JSONDecoder().decode(type, from: data)
    }
}
