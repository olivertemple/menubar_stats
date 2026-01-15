import SwiftUI

/// A minimal sparkline chart for showing trends
struct SparklineView: View {
    let values: [Double]
    let minValue: Double?
    let maxValue: Double?
    let lineColor: Color
    let fillGradient: Bool
    
    init(values: [Double], 
         minValue: Double? = nil, 
         maxValue: Double? = nil,
         lineColor: Color = .accentColor,
         fillGradient: Bool = true) {
        self.values = values
        self.minValue = minValue
        self.maxValue = maxValue
        self.lineColor = lineColor
        self.fillGradient = fillGradient
    }
    
    var body: some View {
        GeometryReader { geometry in
            let normalizedPoints = normalizeValues(in: geometry.size)
            
            if normalizedPoints.count >= 2 {
                ZStack(alignment: .bottom) {
                    // Fill gradient (optional)
                    if fillGradient {
                        Path { path in
                            path.move(to: CGPoint(x: normalizedPoints[0].x, y: geometry.size.height))
                            path.addLine(to: normalizedPoints[0])
                            
                            for point in normalizedPoints.dropFirst() {
                                path.addLine(to: point)
                            }
                            
                            path.addLine(to: CGPoint(x: normalizedPoints.last!.x, y: geometry.size.height))
                            path.closeSubpath()
                        }
                        .fill(
                            LinearGradient(
                                colors: [lineColor.opacity(0.3), lineColor.opacity(0.05)],
                                startPoint: .top,
                                endPoint: .bottom
                            )
                        )
                    }
                    
                    // Line
                    Path { path in
                        path.move(to: normalizedPoints[0])
                        for point in normalizedPoints.dropFirst() {
                            path.addLine(to: point)
                        }
                    }
                    .stroke(lineColor, style: StrokeStyle(lineWidth: 1.5, lineCap: .round, lineJoin: .round))
                }
            } else {
                // Not enough data
                Rectangle()
                    .fill(Color.secondary.opacity(0.1))
                    .overlay(
                        Text("—")
                            .font(.system(size: 10))
                            .foregroundColor(.secondary)
                    )
            }
        }
        .frame(height: 30)
    }
    
    private func normalizeValues(in size: CGSize) -> [CGPoint] {
        guard values.count >= 2 else { return [] }
        
        let min = minValue ?? values.min() ?? 0
        let max = maxValue ?? values.max() ?? 100
        let range = max - min
        
        guard range > 0 else {
            // All values are the same, draw a flat line in the middle
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

struct SparklineView_Previews: PreviewProvider {
    static var previews: some View {
        VStack(spacing: 20) {
            SparklineView(values: [10, 20, 15, 30, 25, 40, 35, 50, 45, 60])
                .frame(width: 200, height: 30)
            
            SparklineView(values: [50, 52, 48, 51, 49, 53, 50, 52, 48], lineColor: .green)
                .frame(width: 200, height: 30)
            
            SparklineView(values: [100, 90, 80, 70, 60, 50, 40], lineColor: .red, fillGradient: false)
                .frame(width: 200, height: 30)
        }
        .padding()
    }
}
