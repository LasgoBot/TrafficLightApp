import SwiftUI

struct CameraOverlayView: View {
    let detections: [DetectionResult]
    let trafficLightDetection: TrafficLightDetection?
    let countdown: TrafficLightCountdown

    var body: some View {
        GeometryReader { proxy in
            ForEach(detections) { result in
                let rect = rectFor(result.boundingBox, in: proxy.size)
                RoundedRectangle(cornerRadius: 8)
                    .stroke(color(for: result.type), lineWidth: 2)
                    .frame(width: rect.width, height: rect.height)
                    .position(x: rect.midX, y: rect.midY)
            }

            VStack {
                HStack {
                    speedAndLightCard
                    Spacer()
                }
                Spacer()
            }
        }
        .allowsHitTesting(false)
        .accessibilityElement(children: .ignore)
        .accessibilityLabel("Camera overlay with detected lanes, vehicles, signs, and traffic light status")
    }

    private var speedAndLightCard: some View {
        VStack(alignment: .leading, spacing: 4) {
            Text("Traffic Light: \(trafficLightDetection?.state.rawValue.capitalized ?? "Unknown")")
            if countdown.showCountdown {
                Text("Green in \(countdown.secondsRemaining)")
                    .font(.title3.bold())
                    .monospacedDigit()
            }
        }
        .font(.caption)
        .padding(10)
        .background(.ultraThinMaterial)
        .clipShape(RoundedRectangle(cornerRadius: 12))
    }

    private func rectFor(_ box: CGRect, in size: CGSize) -> CGRect {
        CGRect(x: box.minX * size.width,
               y: (1 - box.maxY) * size.height,
               width: box.width * size.width,
               height: box.height * size.height)
    }

    private func color(for type: DetectionType) -> Color {
        switch type {
        case .lane: return .green
        case .trafficSign: return .yellow
        case .vehicle: return .red
        case .speedLimit: return .orange
        case .trafficLight: return .mint
        }
    }
}
