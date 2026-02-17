import SwiftUI

struct SettingsView: View {
    @Binding var configuration: DetectionConfiguration
    @Binding var routePreference: RoutePreference

    var body: some View {
        Form {
            Section("Detection") {
                Toggle("Lane Detection", isOn: $configuration.isLaneDetectionEnabled)
                Toggle("Traffic Sign Recognition", isOn: $configuration.isSignDetectionEnabled)
                Toggle("Vehicle Distance Monitoring", isOn: $configuration.isVehicleMonitoringEnabled)
                Toggle("Speed Limit Detection", isOn: $configuration.isSpeedLimitDetectionEnabled)
                Toggle("Traffic Light Detection", isOn: $configuration.isTrafficLightDetectionEnabled)
            }

            Section("Alerts") {
                Slider(value: $configuration.alertSensitivity, in: 0.5...0.95)
                Text("Sensitivity: \(Int(configuration.alertSensitivity * 100))%")
                Toggle("Voice Guidance", isOn: $configuration.voiceGuidanceEnabled)
            }

            Section("Map") {
                Picker("Route", selection: $routePreference) {
                    ForEach(RoutePreference.allCases, id: \.self) { route in
                        Text(route.rawValue.capitalized).tag(route)
                    }
                }
                Toggle("3D Map", isOn: $configuration.map3DEnabled)
                Toggle("Night Mode", isOn: $configuration.nightModeEnabled)
                Toggle("Picture in Picture", isOn: $configuration.pipEnabled)
            }

            Section("Units") {
                Picker("Units", selection: $configuration.preferredUnits) {
                    Text("mph").tag(UnitPreference.mph)
                    Text("km/h").tag(UnitPreference.kmh)
                }
            }

            Section("Performance") {
                Slider(value: $configuration.maxFPS, in: 15...60, step: 1)
                Text("Max FPS \(Int(configuration.maxFPS))")
            }
        }
        .navigationTitle(String(localized: "settings.title"))
    }
}
