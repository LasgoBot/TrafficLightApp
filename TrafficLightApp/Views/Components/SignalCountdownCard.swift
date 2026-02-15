import SwiftUI

struct SignalCountdownCard: View {
    let signal: TrafficSignal?
    let state: DashboardViewModel.ViewState

    var body: some View {
        VStack(alignment: .leading, spacing: 12) {
            Text("Signal Intelligence")
                .font(.headline)
                .foregroundStyle(.white)

            if let signal {
                HStack(alignment: .center, spacing: 16) {
                    ZStack {
                        Circle()
                            .stroke(Color.white.opacity(0.15), lineWidth: 8)
                            .frame(width: 78, height: 78)
                        Circle()
                            .trim(from: 0, to: progress(for: signal))
                            .stroke(color(for: signal.phase), style: StrokeStyle(lineWidth: 8, lineCap: .round))
                            .rotationEffect(.degrees(-90))
                            .frame(width: 78, height: 78)
                        Text(displayCountdown(for: signal))
                            .font(.system(size: 20, weight: .bold, design: .rounded))
                            .foregroundStyle(.white)
                    }

                    VStack(alignment: .leading, spacing: 4) {
                        Text("\(signal.phase.title) • \(signal.intersectionName)")
                            .foregroundStyle(.white)
                            .font(.subheadline.weight(.semibold))
                        Text(statusText(for: signal))
                            .foregroundStyle(.white.opacity(0.9))
                            .font(.caption)
                    }
                }

                Text("Confidence \(Int(signal.confidence * 100))% • \(signal.source)")
                    .font(.caption)
                    .foregroundStyle(.white.opacity(0.82))

                if case let .warning(message) = state {
                    Text(message)
                        .font(.caption)
                        .foregroundStyle(.yellow)
                }
            } else {
                Text("Initializing local traffic-light intelligence…")
                    .foregroundStyle(.white.opacity(0.9))
            }
        }
        .frame(maxWidth: .infinity, alignment: .leading)
        .padding()
        .background(LuxuryTheme.cardGradient)
        .overlay(RoundedRectangle(cornerRadius: 18).stroke(Color.white.opacity(0.22), lineWidth: 1))
        .clipShape(RoundedRectangle(cornerRadius: 18))
    }

    private func displayCountdown(for signal: TrafficSignal) -> String {
        if signal.phase == .green { return "GO" }
        if signal.confidence < AppConfiguration.lowConfidenceThreshold { return "--" }
        return String(signal.countdownToGreen ?? 0)
    }

    private func statusText(for signal: TrafficSignal) -> String {
        if signal.phase == .green {
            return "Proceed if intersection is clear"
        }
        if signal.confidence < AppConfiguration.lowConfidenceThreshold {
            return "Countdown hidden due to low confidence"
        }
        return "Green expected in \(signal.countdownToGreen ?? 0)s"
    }

    private func progress(for signal: TrafficSignal) -> CGFloat {
        guard let remaining = signal.phaseCountdown, remaining > 0 else { return 1 }
        let duration: Int
        switch signal.phase {
        case .green: duration = 30
        case .yellow: duration = 4
        case .red: duration = 30
        case .unknown: duration = 1
        }
        return CGFloat(max(0.05, min(1, Double(duration - remaining) / Double(duration))))
    }

    private func color(for phase: SignalPhase) -> Color {
        switch phase {
        case .red: return .red
        case .yellow: return .yellow
        case .green: return .green
        case .unknown: return .gray
        }
    }
}
