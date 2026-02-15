import SwiftUI

struct RouteProgressCard: View {
    let routeProgress: RouteProgress?

    var body: some View {
        VStack(alignment: .leading, spacing: 10) {
            Text("Navigation")
                .font(.headline)
                .foregroundStyle(.white)

            if let routeProgress {
                HStack {
                    VStack(alignment: .leading, spacing: 5) {
                        Text(routeProgress.destinationName)
                            .font(.title3.weight(.semibold))
                            .foregroundStyle(.white)
                        Text("Next: \(routeProgress.nextManeuver)")
                            .font(.caption)
                            .foregroundStyle(.white.opacity(0.9))
                    }
                    Spacer()
                    Text(routeProgress.distanceDisplay)
                        .font(.title2.weight(.bold))
                        .foregroundStyle(LuxuryTheme.accent)
                }

                HStack(spacing: 14) {
                    Label("ETA \(routeProgress.etaDisplay)", systemImage: "clock.fill")
                    Label(routeProgress.currentRoadName, systemImage: "road.lanes")
                }
                .font(.caption)
                .foregroundStyle(.white.opacity(0.9))
            } else {
                Text("Set destination for full guidance overlay.")
                    .foregroundStyle(.white.opacity(0.85))
            }
        }
        .frame(maxWidth: .infinity, alignment: .leading)
        .padding()
        .background(LuxuryTheme.cardGradient)
        .overlay(RoundedRectangle(cornerRadius: 18).stroke(Color.white.opacity(0.2), lineWidth: 1))
        .clipShape(RoundedRectangle(cornerRadius: 18))
    }
}
