//
//  Drawing.swift
//  TimesUp
//
//  Created by Ken  on 24.09.25.
//

import SwiftUI
import Foundation
import Combine

// MARK: - Drawing Models

/// Repräsentiert einen einzelnen Zeichenstrich
struct DrawingStroke: Identifiable, Equatable {
    var id = UUID()
    var path: Path
    var color: Color
    var lineWidth: CGFloat
    var isErasing: Bool = false
    
    init(path: Path = Path(), color: Color = .black, lineWidth: CGFloat = 3.0, isErasing: Bool = false) {
        self.path = path
        self.color = color
        self.lineWidth = lineWidth
        self.isErasing = isErasing
    }
}

/// Drawing Tools für die Zeichenfunktion
enum DrawingTool: CaseIterable, Identifiable {
    case pen
    case eraser
    case fill
    
    var id: Self { self }
    
    var name: String {
        switch self {
        case .pen: return "Stift"
        case .eraser: return "Radiergummi"
        case .fill: return "Ausfüllen"
        }
    }
    
    var systemImage: String {
        switch self {
        case .pen: return "pencil"
        case .eraser: return "eraser"
        case .fill: return "drop.fill" // Eimer mit Farbtropfen
        }
    }
    
    var color: Color {
        switch self {
        case .pen: return .blue
        case .eraser: return .red
        case .fill: return .orange
        }
    }
}

/// Vordefinierte Farben für das Zeichnen
struct DrawingColors {
    // Nur die wichtigsten 6 Farben für kompakte UI
    static let essential: [Color] = [
        .black, .red, .green, .blue, .yellow, .white
    ]
    
    static let defaultColor: Color = .black
}

// Color Extensions entfernt - sind bereits in SwiftUI definiert

/// Vordefinierte Stiftgrößen
struct DrawingLineWidths {
    static let thin: CGFloat = 2.0
    static let medium: CGFloat = 4.0
    static let thick: CGFloat = 8.0
    static let extraThick: CGFloat = 12.0
    
    static let available: [CGFloat] = [thin, medium, thick, extraThick]
    static let defaultWidth: CGFloat = medium
    
    static func name(for width: CGFloat) -> String {
        switch width {
        case thin: return "Dünn"
        case medium: return "Normal"
        case thick: return "Dick" 
        case extraThick: return "Extra Dick"
        default: return "Custom"
        }
    }
}

/// Zentraler State für das Zeichnen
class DrawingState: ObservableObject {
    // Drawing Content
    @Published var strokes: [DrawingStroke] = []
    @Published var currentStroke: DrawingStroke?
    
    // Tool Settings
    @Published var selectedTool: DrawingTool = .pen
    @Published var selectedColor: Color = DrawingColors.defaultColor
    @Published var selectedLineWidth: CGFloat = DrawingLineWidths.defaultWidth
    
    // UI State
    @Published var canvasSize: CGSize = .zero
    @Published var hasUnsavedChanges: Bool = false
    
    // MARK: - Drawing Actions
    
    /// Startet einen neuen Strich
    func startStroke(at point: CGPoint) {
        var newPath = Path()
        newPath.move(to: point)
        
        let stroke = DrawingStroke(
            path: newPath,
            color: selectedTool == .eraser ? .white : selectedColor,
            lineWidth: selectedLineWidth,
            isErasing: selectedTool == .eraser
        )
        
        currentStroke = stroke
    }
    
    /// Fügt einen Punkt zum aktuellen Strich hinzu
    func addPoint(to point: CGPoint) {
        guard var stroke = currentStroke else { return }
        
        stroke.path.addLine(to: point)
        currentStroke = stroke
    }
    
    /// Beendet den aktuellen Strich
    func finishStroke() {
        guard let stroke = currentStroke else { return }
        
        strokes.append(stroke)
        currentStroke = nil
        hasUnsavedChanges = true
    }
    
    /// Löscht die gesamte Zeichnung
    func clearDrawing() {
        strokes.removeAll()
        currentStroke = nil
        hasUnsavedChanges = false
    }
    
    /// Macht den letzten Strich rückgängig
    func undoLastStroke() {
        guard !strokes.isEmpty else { return }
        strokes.removeLast()
        hasUnsavedChanges = !strokes.isEmpty
    }
    
    // MARK: - Tool Selection
    
    func selectTool(_ tool: DrawingTool) {
        selectedTool = tool
        print("🔧 Tool selected: \(tool)")
    }
    
    /// Fill-Werkzeug: Performance-optimierter Flood-Fill
    func fillArea(at point: CGPoint, with color: Color) {
        guard selectedTool == .fill else { return }
        guard canvasSize.width > 0 && canvasSize.height > 0 else { return }
        
        print("🪣 DEBUG: Starting optimized flood fill at point: \(point)")
        
        // Performance-Check: Bei zu vielen Strokes vereinfachte Strategie
        if strokes.count > 100 {
            print("🚀 Using fast fill mode (too many strokes: \(strokes.count))")
            performFastFill(at: point, with: color)
            return
        }
        
        // Konvertiere Canvas zu Bitmap für Flood-Fill
        let bitmap = createBitmapFromCanvas()
        let targetColor = getTargetColorIntelligent(at: point, in: bitmap, desiredColor: color)
        
        // Prüfe ob der Bereich bereits die gewünschte Farbe hat
        if colorsAreEqual(targetColor, color) {
            print("🪣 Area already has target color, skipping fill")
            return
        }
        
        print("🎯 Target color: \(targetColor), Fill color: \(color)")
        
        // Führe optimierten Flood-Fill aus
        let filledPixels = floodFillOptimized(
            bitmap: bitmap,
            startPoint: point,
            targetColor: targetColor,
            fillColor: color
        )
        
        // Konvertiere zu optimierten Pfaden
        if !filledPixels.isEmpty {
            let fillPath = createOptimizedPath(from: filledPixels, color: color)
            
            if let path = fillPath {
                let fillStroke = DrawingStroke(
                    path: path,
                    color: color,
                    lineWidth: 1,
                    isErasing: false
                )
                strokes.append(fillStroke)
                hasUnsavedChanges = true
                print("🪣 Optimized fill completed with 1 consolidated path")
            }
        } else {
            print("🪣 No area to fill found")
        }
    }
    
    /// Schnelle Fill-Methode für komplexe Canvas-Situationen
    private func performFastFill(at point: CGPoint, with color: Color) {
        // Vereinfachte Rechteck-Füllung basierend auf umgebenden Strokes
        let sampleRadius: CGFloat = 20
        let fillRect = CGRect(
            x: max(0, point.x - sampleRadius),
            y: max(0, point.y - sampleRadius),
            width: min(canvasSize.width - max(0, point.x - sampleRadius), sampleRadius * 2),
            height: min(canvasSize.height - max(0, point.y - sampleRadius), sampleRadius * 2)
        )
        
        let fillPath = Path { path in
            path.addRect(fillRect)
        }
        
        let fillStroke = DrawingStroke(
            path: fillPath,
            color: color,
            lineWidth: 1,
            isErasing: false
        )
        
        strokes.append(fillStroke)
        hasUnsavedChanges = true
        print("🚀 Fast fill completed with rect: \(fillRect)")
    }
    
    // MARK: - Flood Fill Algorithm Implementation
    
    private func createBitmapFromCanvas() -> [[Color]] {
        let width = Int(canvasSize.width)
        let height = Int(canvasSize.height)
        
        print("🖼️ DEBUG: Creating bitmap of size \(width)x\(height) from \(strokes.count) strokes")
        
        // Erstelle leere weiße Bitmap
        var bitmap = Array(repeating: Array(repeating: Color.white, count: width), count: height)
        
        // Rasterisiere alle existierenden Strokes in die Bitmap
        for (index, stroke) in strokes.enumerated() {
            print("🖊️ DEBUG: Processing stroke \(index + 1)/\(strokes.count)")
            rasterizeStrokeIntoBitmap(&bitmap, stroke: stroke)
        }
        
        return bitmap
    }
    
    private func rasterizeStrokeIntoBitmap(_ bitmap: inout [[Color]], stroke: DrawingStroke) {
        let width = bitmap[0].count
        let height = bitmap.count
        let path = stroke.path
        let bounds = path.boundingRect
        
        // Viel präzisere Rasterisierung für alle Formen
        let perimeter = (bounds.width + bounds.height) * 2
        let steps = max(Int(perimeter * 4), 500) // 4x mehr Steps für bessere Precision
        
        print("🎯 Rasterizing \(bounds.width)x\(bounds.height) with \(steps) steps")
        
        for i in 0...steps {
            let t = CGFloat(i) / CGFloat(steps)
            
            guard let point = path.trimmedPath(from: 0, to: t).currentPoint else { continue }
            
            let x = Int(point.x)
            let y = Int(point.y)
            
            let radius = max(Int(stroke.lineWidth / 2), 1)
            
            for dy in -radius...radius {
                for dx in -radius...radius {
                    let px = x + dx
                    let py = y + dy
                    
                    if px >= 0 && px < width && py >= 0 && py < height {
                        let distance = sqrt(Double(dx*dx + dy*dy))
                        if distance <= Double(radius) {
                            if stroke.isErasing {
                                bitmap[py][px] = .white
                            } else {
                                bitmap[py][px] = stroke.color
                            }
                        }
                    }
                }
            }
        }
    }
    
    private func fillRectangleInBitmap(_ bitmap: inout [[Color]], rect: CGRect, color: Color, isErasing: Bool) {
        let width = bitmap[0].count
        let height = bitmap.count
        
        let startX = max(0, Int(rect.minX))
        let endX = min(width - 1, Int(rect.maxX))
        let startY = max(0, Int(rect.minY))
        let endY = min(height - 1, Int(rect.maxY))
        
        for y in startY...endY {
            for x in startX...endX {
                if isErasing {
                    bitmap[y][x] = .white
                } else {
                    bitmap[y][x] = color
                }
            }
        }
    }
    
    private func getPixelColor(at point: CGPoint, in bitmap: [[Color]]) -> Color {
        let x = Int(point.x)
        let y = Int(point.y)
        
        if y >= 0 && y < bitmap.count && x >= 0 && x < bitmap[0].count {
            return bitmap[y][x]
        }
        return .white
    }
    
    /// Intelligente Zielfarben-Erkennung für besseres Fill-Verhalten
    private func getTargetColorIntelligent(at point: CGPoint, in bitmap: [[Color]], desiredColor: Color) -> Color {
        let directColor = getPixelColor(at: point, in: bitmap)
        
        print("🔍 DEBUG: Direct pixel color: \(directColor), Desired fill color: \(desiredColor)")
        
        // Wenn direkte Farbe != gewünschte Farbe, verwende sie (das ist der Normalfall)
        if !colorsAreEqual(directColor, desiredColor) {
            print("🎯 Direct hit works: target=\(directColor), fill=\(desiredColor)")
            return directColor
        }
        
        // Wenn sie gleich sind, schaue in viel größerem Umkreis nach anderen Farben
        print("🔍 Same color detected (\(directColor) == \(desiredColor)), checking surroundings...")
        let searchRadius = 15 // Viel größerer Radius für große Formen
        var surroundingColors: [Color] = []
        var checkedPoints = 0
        
        for dy in -searchRadius...searchRadius {
            for dx in -searchRadius...searchRadius {
                if dx == 0 && dy == 0 { continue } // Skip center point
                
                let checkPoint = CGPoint(x: point.x + CGFloat(dx), y: point.y + CGFloat(dy))
                let surroundingColor = getPixelColor(at: checkPoint, in: bitmap)
                checkedPoints += 1
                
                // Sammle ALLE unterschiedlichen Farben
                if !colorsAreEqual(surroundingColor, desiredColor) {
                    surroundingColors.append(surroundingColor)
                }
            }
        }
        
        print("🔍 Checked \(checkedPoints) surrounding points")
        
        print("🔍 Found \(surroundingColors.count) different surrounding colors")
        
        // Finde die häufigste umgebende Farbe (die nicht die gewünschte ist)
        if let mostCommonColor = findMostCommonColor(in: surroundingColors) {
            print("🎯 Using surrounding color: \(mostCommonColor)")
            return mostCommonColor
        }
        
        // Letzter Fallback: Wenn alles die gleiche Farbe ist, verwende weiß oder schwarz als Kontrast
        print("🔍 No different surrounding colors found")
        if colorsAreEqual(desiredColor, .white) {
            print("🎯 Fallback: Using black as contrast to white")
            return .black
        } else if colorsAreEqual(desiredColor, .black) {
            print("🎯 Fallback: Using white as contrast to black")
            return .white
        } else {
            print("🎯 Fallback: Using white as default contrast")
            return .white
        }
    }
    
    private func findMostCommonColor(in colors: [Color]) -> Color? {
        guard !colors.isEmpty else { return nil }
        
        var colorCounts: [String: (color: Color, count: Int)] = [:]
        
        for color in colors {
            let key = "\(color)" // Simple string representation
            if let existing = colorCounts[key] {
                colorCounts[key] = (color: existing.color, count: existing.count + 1)
            } else {
                colorCounts[key] = (color: color, count: 1)
            }
        }
        
        return colorCounts.values.max(by: { $0.count < $1.count })?.color
    }
    
    private func floodFillOptimized(bitmap: [[Color]], startPoint: CGPoint, targetColor: Color, fillColor: Color) -> Set<CGPoint> {
        let width = bitmap[0].count
        let height = bitmap.count
        let startX = Int(startPoint.x)
        let startY = Int(startPoint.y)
        
        guard startX >= 0 && startX < width && startY >= 0 && startY < height else {
            return Set<CGPoint>()
        }
        
        // Dynamisches Pixel-Limit basierend auf Canvas-Größe
        let totalCanvasPixels = width * height
        let maxFillPixels = totalCanvasPixels // Erlaube die komplette Canvas zu füllen!
        
        print("🎯 DEBUG: Canvas size: \(width)x\(height) = \(totalCanvasPixels) pixels, max fill: \(maxFillPixels)")
        
        var filledPixels = Set<CGPoint>()
        var stack = [CGPoint(x: startX, y: startY)]
        
        while !stack.isEmpty {
            let point = stack.removeLast()
            let x = Int(point.x)
            let y = Int(point.y)
            
            // Prüfe Grenzen
            guard x >= 0 && x < width && y >= 0 && y < height else { continue }
            
            // Prüfe ob Pixel bereits besucht
            guard !filledPixels.contains(point) else { continue }
            
            // Prüfe ob Pixel die Zielfarbe hat
            guard colorsAreEqual(bitmap[y][x], targetColor) else { continue }
            
            // Füge Pixel zu gefüllten Pixeln hinzu
            filledPixels.insert(point)
            
            // Füge benachbarte Pixel zum Stack hinzu
            stack.append(CGPoint(x: x + 1, y: y))
            stack.append(CGPoint(x: x - 1, y: y))
            stack.append(CGPoint(x: x, y: y + 1))
            stack.append(CGPoint(x: x, y: y - 1))
            
            // Dynamisches Limit - verhindere nur echte Endlos-Schleifen
            if filledPixels.count > maxFillPixels {
                print("🚨 Flood fill reached canvas limit, stopping at \(filledPixels.count) pixels")
                break
            }
            
            // Progress-Update bei großen Füllungen
            if filledPixels.count % 5000 == 0 {
                print("🎨 Flood fill progress: \(filledPixels.count) pixels filled")
            }
        }
        
        let fillPercentage = (Double(filledPixels.count) / Double(totalCanvasPixels)) * 100
        print("🎯 Flood fill completed: \(filledPixels.count) pixels (\(String(format: "%.1f", fillPercentage))% of canvas)")
        
        return filledPixels
    }
    
    private func createOptimizedPath(from pixels: Set<CGPoint>, color: Color) -> Path? {
        guard !pixels.isEmpty else { return nil }
        
        // Finde Bounding Rectangle des gefüllten Bereichs
        let pixelArray = Array(pixels)
        let minX = pixelArray.map(\.x).min()!
        let maxX = pixelArray.map(\.x).max()!
        let minY = pixelArray.map(\.y).min()!
        let maxY = pixelArray.map(\.y).max()!
        
        let fillRect = CGRect(
            x: minX,
            y: minY,
            width: maxX - minX + 1,
            height: maxY - minY + 1
        )
        
        let area = fillRect.width * fillRect.height
        let pixelRatio = Double(pixels.count) / Double(area)
        
        print("🎯 Fill analysis: \(pixels.count) pixels in \(Int(area)) area = \(String(format: "%.1f", pixelRatio * 100))% fill ratio")
        
        // Nur bei sehr hoher Füllung UND kleinen Bereichen ein Rechteck verwenden
        if pixelRatio > 0.95 && area < 5000 { 
            print("🎯 Using single rectangle (small + dense)")
            return Path { path in
                path.addRect(fillRect)
            }
        } else {
            // Für alle anderen Fälle: Präzise Pixel-basierte Pfade
            print("🎯 Using precise pixel-based path")
            return createPrecisePathFromPixels(pixels)
        }
    }
    
    private func createPrecisePathFromPixels(_ pixels: Set<CGPoint>) -> Path {
        return Path { path in
            // Gruppiere in horizontale Linien für bessere Performance
            let sortedPixels = Array(pixels).sorted { $0.y < $1.y || ($0.y == $1.y && $0.x < $1.x) }
            
            var currentLineStart: CGPoint?
            var currentLineEnd: CGPoint?
            
            for pixel in sortedPixels {
                if let lineStart = currentLineStart,
                   let lineEnd = currentLineEnd,
                   pixel.y == lineStart.y && pixel.x == lineEnd.x + 1 {
                    // Erweitere aktuelle Linie
                    currentLineEnd = pixel
                } else {
                    // Füge vorherige Linie hinzu
                    if let lineStart = currentLineStart, let lineEnd = currentLineEnd {
                        path.addRect(CGRect(
                            x: lineStart.x,
                            y: lineStart.y,
                            width: lineEnd.x - lineStart.x + 1,
                            height: 1
                        ))
                    }
                    // Starte neue Linie
                    currentLineStart = pixel
                    currentLineEnd = pixel
                }
            }
            
            // Füge letzte Linie hinzu
            if let lineStart = currentLineStart, let lineEnd = currentLineEnd {
                path.addRect(CGRect(
                    x: lineStart.x,
                    y: lineStart.y,
                    width: lineEnd.x - lineStart.x + 1,
                    height: 1
                ))
            }
        }
    }
    
    private func colorsAreEqual(_ color1: Color, _ color2: Color) -> Bool {
        // Vereinfachter Farbvergleich
        return color1 == color2
    }
    
    func selectColor(_ color: Color) {
        selectedColor = color
        if selectedTool == .eraser {
            selectedTool = .pen // Automatisch zu Stift wechseln bei Farbwahl
        }
    }
    
    func selectLineWidth(_ width: CGFloat) {
        selectedLineWidth = width
    }
    
    // MARK: - Computed Properties
    
    var isEmpty: Bool {
        return strokes.isEmpty && currentStroke == nil
    }
    
    var strokeCount: Int {
        return strokes.count + (currentStroke != nil ? 1 : 0)
    }
    
    /// Reset für neuen Begriff
    func resetForNewTerm() {
        clearDrawing()
    }
}

