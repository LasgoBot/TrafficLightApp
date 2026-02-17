import ActivityKit
import SwiftUI
import WidgetKit

@available(iOS 16.2, *)
struct TrafficLiveActivity: Widget {
    var body: some WidgetConfiguration {
        ActivityConfiguration(for: TrafficActivityAttributes.self) { context in
            // Lock screen view
            lockScreenView(context: context)
        } dynamicIsland: { context in
            DynamicIsland {
                // Expanded view
                DynamicIslandExpandedRegion(.leading) {
                    HStack(spacing: 4) {
                        Text(context.state.trafficLightState.displayColor)
                            .font(.system(size: 32))
                        VStack(alignment: .leading, spacing: 2) {
                            Text("Signal")
                                .font(.caption2)
                                .foregroundColor(.secondary)
                            Text(context.state.trafficLightState.rawValue.capitalized)
                                .font(.caption)
                                .bold()
                        }
                    }
                }
                
                DynamicIslandExpandedRegion(.trailing) {
                    VStack(alignment: .trailing, spacing: 2) {
                        Text("Next Green")
                            .font(.caption2)
                            .foregroundColor(.secondary)
                        Text("\(context.state.countdownSeconds)s")
                            .font(.title3)
                            .bold()
                            .foregroundColor(context.state.trafficLightState == .red ? .red : .green)
                    }
                }
                
                DynamicIslandExpandedRegion(.center) {
                    VStack(spacing: 4) {
                        Text("GLOSA Speed")
                            .font(.caption2)
                            .foregroundColor(.secondary)
                        HStack(alignment: .firstTextBaseline, spacing: 2) {
                            Text("\(context.state.targetSpeed)")
                                .font(.system(size: 28, weight: .bold))
                            Text("mph")
                                .font(.caption)
                                .foregroundColor(.secondary)
                        }
                    }
                }
                
                DynamicIslandExpandedRegion(.bottom) {
                    HStack {
                        Image(systemName: "location.fill")
                            .font(.caption2)
                        Text(context.attributes.intersectionName)
                            .font(.caption)
                            .lineLimit(1)
                    }
                    .foregroundColor(.secondary)
                }
            } compactLeading: {
                // Compact leading view
                Text(context.state.trafficLightState.displayColor)
                    .font(.system(size: 20))
            } compactTrailing: {
                // Compact trailing view
                Text("\(context.state.countdownSeconds)s")
                    .font(.system(size: 14, weight: .semibold))
                    .foregroundColor(context.state.trafficLightState == .red ? .red : .green)
            } minimal: {
                // Minimal view when multiple activities are running
                Text(context.state.trafficLightState.displayColor)
                    .font(.system(size: 18))
            }
        }
    }
    
    private func lockScreenView(context: ActivityViewContext<TrafficActivityAttributes>) -> some View {
        VStack(spacing: 12) {
            HStack {
                VStack(alignment: .leading, spacing: 4) {
                    Text(context.attributes.intersectionName)
                        .font(.headline)
                    Text("Traffic Signal")
                        .font(.caption)
                        .foregroundColor(.secondary)
                }
                Spacer()
                Text(context.state.trafficLightState.displayColor)
                    .font(.system(size: 40))
            }
            
            HStack(spacing: 20) {
                VStack(alignment: .leading, spacing: 4) {
                    Text("Next Green")
                        .font(.caption)
                        .foregroundColor(.secondary)
                    Text("\(context.state.countdownSeconds)s")
                        .font(.title2)
                        .bold()
                        .foregroundColor(context.state.trafficLightState == .red ? .red : .green)
                }
                
                Spacer()
                
                VStack(alignment: .trailing, spacing: 4) {
                    Text("Target Speed")
                        .font(.caption)
                        .foregroundColor(.secondary)
                    HStack(alignment: .firstTextBaseline, spacing: 2) {
                        Text("\(context.state.targetSpeed)")
                            .font(.title2)
                            .bold()
                        Text("mph")
                            .font(.caption)
                            .foregroundColor(.secondary)
                    }
                }
            }
        }
        .padding()
        .activityBackgroundTint(Color.black.opacity(0.8))
        .activitySystemActionForegroundColor(Color.white)
    }
}

@available(iOS 16.2, *)
extension TrafficActivityAttributes {
    static var preview: TrafficActivityAttributes {
        TrafficActivityAttributes(intersectionName: "Main St & 1st Ave", geoID: "test_123")
    }
}

@available(iOS 16.2, *)
extension TrafficActivityAttributes.ContentState {
    static var redLight: TrafficActivityAttributes.ContentState {
        TrafficActivityAttributes.ContentState(
            trafficLightState: .red,
            countdownSeconds: 14,
            targetSpeed: 30,
            lastUpdate: Date()
        )
    }
    
    static var greenLight: TrafficActivityAttributes.ContentState {
        TrafficActivityAttributes.ContentState(
            trafficLightState: .green,
            countdownSeconds: 8,
            targetSpeed: 35,
            lastUpdate: Date()
        )
    }
}
