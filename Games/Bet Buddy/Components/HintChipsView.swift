import SwiftUI

struct HintItem: Identifiable, Hashable {
    let id = UUID()
    let text: String
    var isChecked: Bool = false
}

struct HintChipsView: View {
    @Binding var items: [HintItem]

    var body: some View {
        FlexibleFlowLayout(spacing: 8) {
            ForEach($items) { $item in
                Button {
                    item.isChecked.toggle()
                    HapticsService.impact(.light)
                } label: {
                    HStack(spacing: 6) {
                        Image(systemName: item.isChecked ? "checkmark.circle.fill" : "circle")
                            .font(.system(size: 16))
                            .foregroundStyle(item.isChecked ? Color.green : Color.white.opacity(0.5))
                        
                        Text(item.text)
                            .font(.system(size: 14, weight: .medium))
                            .foregroundStyle(.white)
                            .lineLimit(1)
                            .fixedSize(horizontal: true, vertical: false)
                    }
                    .padding(.horizontal, 12)
                    .padding(.vertical, 10)
                    .frame(maxWidth: .infinity)
                    .background(
                        RoundedRectangle(cornerRadius: 12)
                            .fill(item.isChecked ? Color.white.opacity(0.15) : Color.white.opacity(0.08))
                    )
                    .overlay(
                        RoundedRectangle(cornerRadius: 12)
                            .stroke(item.isChecked ? Color.green.opacity(0.5) : Color.white.opacity(0.1), lineWidth: 1)
                    )
                }
                .buttonStyle(.plain)
            }
        }
        .frame(maxWidth: .infinity)
    }
}

struct FlexibleFlowLayout: Layout {
    var spacing: CGFloat = 8

    struct LayoutResult {
        var size: CGSize
        var frames: [CGRect]
    }

    func sizeThatFits(proposal: ProposedViewSize, subviews: Subviews, cache: inout ()) -> CGSize {
        return calculateLayout(proposal: proposal, subviews: subviews).size
    }

    func placeSubviews(in bounds: CGRect, proposal: ProposedViewSize, subviews: Subviews, cache: inout ()) {
        let result = calculateLayout(proposal: proposal, subviews: subviews)
        
        for (index, frame) in result.frames.enumerated() {
            let position = CGPoint(x: bounds.minX + frame.origin.x, y: bounds.minY + frame.origin.y)
            subviews[index].place(
                at: position,
                proposal: ProposedViewSize(width: frame.width, height: frame.height)
            )
        }
    }

    private func calculateLayout(proposal: ProposedViewSize, subviews: Subviews) -> LayoutResult {
        // FIX: UIScreen.main ersetzt durch modernen Fallback
        let screenWidth = (UIApplication.shared.connectedScenes.first as? UIWindowScene)?.screen.bounds.width ?? 375
        let maxWidth = proposal.width ?? screenWidth
        
        var rows: [[Int]] = [[]]
        var currentRowWidth: CGFloat = 0
        
        for (index, subview) in subviews.enumerated() {
            let size = subview.sizeThatFits(.unspecified)
            
            if currentRowWidth + size.width + spacing > maxWidth && !rows.last!.isEmpty {
                rows.append([])
                currentRowWidth = 0
            }
            
            rows[rows.count - 1].append(index)
            currentRowWidth += size.width + spacing
        }
        
        var frames: [CGRect] = Array(repeating: .zero, count: subviews.count)
        var currentY: CGFloat = 0
        
        for (rowIndex, rowIndices) in rows.enumerated() {
            let rowItems = rowIndices.map { subviews[$0] }
            let totalSpacing = CGFloat(rowItems.count - 1) * spacing
            let naturalWidths = rowItems.map { $0.sizeThatFits(.unspecified).width }
            let totalNaturalWidth = naturalWidths.reduce(0, +)
            
            let availableSpace = maxWidth - totalSpacing
            let extraSpace = max(0, availableSpace - totalNaturalWidth)
            
            let shouldJustify = rowIndex < rows.count - 1 || rowItems.count > 1
            let expansionPerItem = shouldJustify ? (extraSpace / CGFloat(rowItems.count)) : 0
            
            var currentX: CGFloat = 0
            var maxHeight: CGFloat = 0
            
            // FIX: 'i' was never used -> '_'
            for (_, subviewIndex) in rowIndices.enumerated() {
                let subview = subviews[subviewIndex]
                let naturalSize = subview.sizeThatFits(.unspecified)
                
                let newWidth = naturalSize.width + expansionPerItem
                
                frames[subviewIndex] = CGRect(x: currentX, y: currentY, width: newWidth, height: naturalSize.height)
                
                currentX += newWidth + spacing
                maxHeight = max(maxHeight, naturalSize.height)
            }
            
            currentY += maxHeight + spacing
        }
        
        return LayoutResult(size: CGSize(width: maxWidth, height: currentY - spacing), frames: frames)
    }
}
