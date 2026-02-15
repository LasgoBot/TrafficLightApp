import SwiftUI

struct DetectionOverlayView: View {
    let detections: [DetectionObservation]

    var body: some View {
        GeometryReader { proxy in
            ForEach(detections) { item in
                let rect = convert(item.boundingBox, in: proxy.size)
                RoundedRectangle(cornerRadius: 8)
                    .stroke(color(for: item.category), lineWidth: 2)
                    .frame(width: rect.width, height: rect.height)
                    .position(x: rect.midX, y: rect.midY)
                    .overlay(alignment: .topLeading) {
                        Text("\(item.category.rawValue.capitalized) \(Int(item.confidence * 100))%")
                            .font(.caption2.bold())
                            .padding(4)
                            .background(color(for: item.category).opacity(0.8))
                            .clipShape(RoundedRectangle(cornerRadius: 6))
                            .offset(x: 2, y: 2)
                    }
            }
        }
        .allowsHitTesting(false)
    }

    private func convert(_ rect: CGRect, in size: CGSize) -> CGRect {
        CGRect(x: rect.minX * size.width,
               y: (1 - rect.maxY) * size.height,
               width: rect.width * size.width,
               height: rect.height * size.height)
    }

    private func color(for category: DetectionCategory) -> Color {
        switch category {
        case .lane: return .cyan
        case .trafficSign: return .yellow
        case .vehicle: return .red
        case .speedLimit: return .orange
        }
    }
}
