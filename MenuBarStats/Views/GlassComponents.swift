import SwiftUI

// MARK: - Glass Panel Container
struct GlassPanel<Content: View>: View {
    let content: Content
    
    init(@ViewBuilder content: () -> Content) {
        self.content = content()
    }
    
    var body: some View {
        content
            .background(.ultraThinMaterial, in: RoundedRectangle(cornerRadius: 16, style: .continuous))
            .overlay(
                RoundedRectangle(cornerRadius: 16, style: .continuous)
                    .strokeBorder(Color.white.opacity(0.25), lineWidth: 1)
            )
            .shadow(color: Color.black.opacity(0.15), radius: 20, x: 0, y: 8)
    }
}

// MARK: - Glass Row (Interactive Card)
struct GlassRow<Content: View>: View {
    let content: Content
    let action: (() -> Void)?
    
    @State private var isHovered = false
    
    init(action: (() -> Void)? = nil, @ViewBuilder content: () -> Content) {
        self.action = action
        self.content = content()
    }
    
    var body: some View {
        let base = content
            .padding(.horizontal, 12)
            .padding(.vertical, 8)
            .background(
                RoundedRectangle(cornerRadius: 10, style: .continuous)
                    .fill(.thinMaterial)
                    .opacity(isHovered ? 1.0 : 0.8)
            )
            .scaleEffect(isHovered ? 1.01 : 1.0)
            .onHover { hovering in
                withAnimation(.easeInOut(duration: 0.15)) {
                    isHovered = hovering
                }
            }
            .animation(.easeInOut(duration: 0.15), value: isHovered)

        // Only install a tap gesture when an explicit action is provided.
        if action != nil {
            base
                .contentShape(Rectangle())
                .onTapGesture {
                    action?()
                }
        } else {
            base
                .contentShape(Rectangle())
        }
    }
}

// MARK: - Section Divider
struct SectionDivider: View {
    var body: some View {
        Rectangle()
            .fill(Color.primary.opacity(0.15))
            .frame(height: 1)
            .cornerRadius(0.5)
            .padding(.vertical, 6)
    }
}

// MARK: - Header Pill
struct HeaderPill<Content: View>: View {
    let content: Content
    
    init(@ViewBuilder content: () -> Content) {
        self.content = content()
    }
    
    var body: some View {
        content
            .padding(.horizontal, 14)
            .padding(.vertical, 10)
            .background(.thinMaterial, in: RoundedRectangle(cornerRadius: 14, style: .continuous))
    }
}

// MARK: - Chevron Accessory
struct ChevronAccessory: View {
    let isExpanded: Bool
    
    var body: some View {
        Image(systemName: "chevron.right")
            .font(.system(size: 12, weight: .semibold))
            .foregroundColor(.secondary)
            .opacity(0.6)
            .rotationEffect(.degrees(isExpanded ? 90 : 0))
            .frame(width: 14, alignment: .center)
            .animation(.easeInOut(duration: 0.15), value: isExpanded)
    }
}

// MARK: - Subtle Sparkline (Tailscale Style)
struct SubtleSparkline: View {
    let values: [Double]
    let color: Color
    
    init(values: [Double], color: Color = .accentColor) {
        self.values = values
        self.color = color
    }
    
    var body: some View {
        GeometryReader { geometry in
            let normalizedPoints = normalizeValues(in: geometry.size)
            
            if normalizedPoints.count >= 2 {
                Path { path in
                    path.move(to: normalizedPoints[0])
                    for point in normalizedPoints.dropFirst() {
                        path.addLine(to: point)
                    }
                }
                .stroke(
                    color.opacity(0.4),
                    style: StrokeStyle(lineWidth: 1.5, lineCap: .round, lineJoin: .round)
                )
                .blur(radius: 0.5)
            }
        }
        .frame(height: 20)
    }
    
    private func normalizeValues(in size: CGSize) -> [CGPoint] {
        guard values.count >= 2 else { return [] }
        
        let min = values.min() ?? 0
        let max = values.max() ?? 100
        let range = max - min
        
        guard range > 0 else {
            let y = size.height / 2
            return values.enumerated().map { index, _ in
                let x = (CGFloat(index) / CGFloat(values.count - 1)) * size.width
                return CGPoint(x: x, y: y)
            }
        }
        
        return values.enumerated().map { index, value in
            let x = (CGFloat(index) / CGFloat(values.count - 1)) * size.width
            let normalizedValue = (value - min) / range
            let y = size.height - (normalizedValue * size.height)
            return CGPoint(x: x, y: y)
        }
    }
}

// MARK: - Section Header (Uppercase, Small)
struct SectionHeader: View {
    let title: String
    
    var body: some View {
        Text(title.uppercased())
            .font(.system(.footnote, design: .rounded))
            .fontWeight(.medium)
            .foregroundColor(.secondary)
            .opacity(0.7)
            .padding(.horizontal, 4)
            .padding(.top, 8)
            .padding(.bottom, 4)
    }
}
