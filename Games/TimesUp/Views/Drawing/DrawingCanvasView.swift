//
//  DrawingCanvasView.swift
//  TimesUp
//
//  Created by Ken  on 24.09.25.
//

import SwiftUI

// MARK: - Drawing Canvas

struct DrawingCanvasView: View {
    @ObservedObject var drawingState: DrawingState
    
    var body: some View {
        GeometryReader { geometry in
            ZStack {
                // Interactive Drawing Area (ÜBER dem Canvas!)
                Rectangle()
                    .fill(Color.clear) // Transparent aber interaktiv
                    .contentShape(Rectangle()) // Macht den ganzen Bereich interaktiv
                    .allowsHitTesting(true)
                    .onAppear {
                        drawingState.canvasSize = geometry.size
                    }
                    .onTapGesture { location in
                        // Tap-Geste für Fill-Tool
                        if drawingState.selectedTool == .fill {
                            print("🪣 DEBUG: Fill tap at: \(location)")
                            drawingState.fillArea(at: location, with: drawingState.selectedColor)
                        } else {
                            // Normaler Punkt für andere Tools
                            drawingState.startStroke(at: location)
                            drawingState.addPoint(to: location)
                            drawingState.finishStroke()
                        }
                    }
                    .gesture(
                        DragGesture(minimumDistance: 0, coordinateSpace: .local)
                            .onChanged { value in
                                handleDragChanged(value, in: geometry.size)
                            }
                            .onEnded { value in
                                handleDragEnded(value)
                            }
                    )
                
                // Drawing Canvas (UNTER dem Interactive Layer!)
                Canvas { context, size in
                    // Render all completed strokes
                    for stroke in drawingState.strokes {
                        renderStroke(stroke, context: context)
                    }
                    
                    // Render current stroke being drawn
                    if let currentStroke = drawingState.currentStroke {
                        renderStroke(currentStroke, context: context)
                    }
                }
                .background(Color.white) // Weißer Hintergrund für Canvas
                .allowsHitTesting(false) // Canvas soll keine Touch-Events konsumieren!
                
                // Empty State Message
                if drawingState.isEmpty {
                    EmptyCanvasView()
                        .allowsHitTesting(false) // Auch diese soll nicht Touch-Events blockieren
                }
            }
        }
        .clipped() // Verhindert Zeichnen außerhalb des Canvas
    }
    
    // MARK: - Drawing Logic
    
    private func handleDragChanged(_ value: DragGesture.Value, in canvasSize: CGSize) {
        let point = value.location
        
        // Ensure point is within bounds
        guard point.x >= 0, point.y >= 0, point.x <= canvasSize.width, point.y <= canvasSize.height else {
            return
        }
        
        if drawingState.currentStroke == nil {
            drawingState.startStroke(at: point)
        } else {
            drawingState.addPoint(to: point)
        }
    }
    
    private func handleDragEnded(_ value: DragGesture.Value) {
        drawingState.finishStroke()
    }
    
    private func renderStroke(_ stroke: DrawingStroke, context: GraphicsContext) {
        // Configure stroke style
        let strokeStyle = StrokeStyle(
            lineWidth: stroke.lineWidth,
            lineCap: .round,
            lineJoin: .round
        )
        
        if stroke.isErasing {
            // Eraser: Use white color to "erase" on white background
            context.stroke(
                stroke.path,
                with: .color(.white),
                style: strokeStyle
            )
        } else {
            // Check if this looks like a filled shape (created by fill tool)
            let bounds = stroke.path.boundingRect
            let area = bounds.width * bounds.height
            let isLikelyFillShape = area > 100 && stroke.lineWidth <= 2
            
            if isLikelyFillShape {
                // Fill the shape
                context.fill(stroke.path, with: .color(stroke.color))
            } else {
                // Normal drawing stroke
                context.stroke(
                    stroke.path,
                    with: .color(stroke.color),
                    style: strokeStyle
                )
            }
        }
    }
}

// MARK: - Empty Canvas State

struct EmptyCanvasView: View {
    var body: some View {
        VStack(spacing: 15) {
            Image(systemName: "scribble.variable")
                .font(.system(size: 48))
                .foregroundColor(.gray.opacity(0.6))
            
            Text(LocalizedStringKey("Bereit zum Zeichnen!"))
                .font(.title2)
                .fontWeight(.semibold)
                .foregroundColor(.gray)
            
            Text(LocalizedStringKey("Tippe und ziehe, um zu zeichnen"))
                .font(.subheadline)
                .foregroundColor(.gray.opacity(0.8))
        }
        .frame(maxWidth: .infinity, maxHeight: .infinity)
        .background(Color.gray.opacity(0.05))
    }
}

// MARK: - Drawing Performance Optimizations

extension DrawingCanvasView {
    
    /// Optimiert das Rendering für bessere Performance
    private func optimizedRenderStroke(_ stroke: DrawingStroke, context: GraphicsContext, viewSize: CGSize) {
        // Nur zeichnen wenn Stroke im sichtbaren Bereich ist
        let strokeBounds = stroke.path.boundingRect
        let viewBounds = CGRect(origin: .zero, size: viewSize)
        
        guard strokeBounds.intersects(viewBounds) else { return }
        
        renderStroke(stroke, context: context)
    }
    
    /// Berechnet die Bounding Box für Performance-Optimierungen
    private func calculateBoundingBox(for strokes: [DrawingStroke]) -> CGRect {
        guard !strokes.isEmpty else { return .zero }
        
        var minX: CGFloat = .greatestFiniteMagnitude
        var minY: CGFloat = .greatestFiniteMagnitude
        var maxX: CGFloat = -.greatestFiniteMagnitude
        var maxY: CGFloat = -.greatestFiniteMagnitude
        
        for stroke in strokes {
            let bounds = stroke.path.boundingRect
            minX = min(minX, bounds.minX)
            minY = min(minY, bounds.minY)
            maxX = max(maxX, bounds.maxX)
            maxY = max(maxY, bounds.maxY)
        }
        
        return CGRect(
            x: minX,
            y: minY,
            width: maxX - minX,
            height: maxY - minY
        )
    }
}

// MARK: - Touch Detection Extensions

extension DrawingCanvasView {
    
    /// Erweiterte Touch-Detection für verschiedene Input-Methoden
    private func handleTouchInput(_ value: DragGesture.Value, in canvasSize: CGSize) -> CGPoint {
        var point = value.location
        
        // Boundary checking
        point.x = max(0, min(point.x, canvasSize.width))
        point.y = max(0, min(point.y, canvasSize.height))
        
        return point
    }
    
    /// Erkennt verschiedene Zeichengeschwindigkeiten für adaptive Strichstärke
    private func adaptiveLineWidth(for velocity: CGSize, baseWidth: CGFloat) -> CGFloat {
        let speed = sqrt(velocity.width * velocity.width + velocity.height * velocity.height)
        let speedFactor = min(max(speed / 100, 0.5), 2.0) // Begrenzt auf 0.5x bis 2x
        return baseWidth * (2.0 - speedFactor) // Langsamere Striche = dicker
    }
}

#Preview {
    DrawingCanvasView(drawingState: DrawingState())
        .frame(height: 400)
        .padding()
}
