import SwiftUI

struct DriveAssistView: View {
    @StateObject private var cameraViewModel = CameraViewModel()
    @StateObject private var navigationViewModel = NavigationViewModel()
    @StateObject private var mapViewModel = MapViewModel()

    @State private var showSettings = false
    @State private var mapMode = false

    var body: some View {
        ZStack {
            if mapMode {
                MapView(navigationViewModel: navigationViewModel, mapViewModel: mapViewModel)
                    .ignoresSafeArea()
            } else {
                CameraPreviewView(session: cameraViewModel.cameraManager.session)
                    .ignoresSafeArea()
                    .accessibilityHidden(true)

                CameraOverlayView(detections: cameraViewModel.detectionResults,
                                  trafficLightDetection: cameraViewModel.trafficLightDetection,
                                  countdown: cameraViewModel.countdown)
                    .ignoresSafeArea()

                if cameraViewModel.configuration.pipEnabled {
                    MapView(navigationViewModel: navigationViewModel, mapViewModel: mapViewModel)
                        .frame(width: 160, height: 220)
                        .clipShape(RoundedRectangle(cornerRadius: 16))
                        .overlay(RoundedRectangle(cornerRadius: 16).stroke(.white.opacity(0.5), lineWidth: 1))
                        .padding()
                        .frame(maxWidth: .infinity, maxHeight: .infinity, alignment: .topTrailing)
                }
            }

            VStack {
                statusBar
                Spacer()
                if let warning = cameraViewModel.reliabilityMessage {
                    Text(warning)
                        .font(.caption)
                        .padding(8)
                        .background(.ultraThinMaterial)
                        .clipShape(Capsule())
                }
            }
            .padding()

            if let permissionMessage = cameraViewModel.permissionMessage {
                Color.black.opacity(0.45).ignoresSafeArea()
                VStack(spacing: 8) {
                    Image(systemName: "camera.viewfinder")
                        .font(.largeTitle)
                    Text(permissionMessage)
                        .multilineTextAlignment(.center)
                    Text("Enable permissions in Settings > Privacy.")
                        .font(.footnote)
                        .foregroundStyle(.secondary)
                }
                .padding()
                .background(.ultraThinMaterial)
                .clipShape(RoundedRectangle(cornerRadius: 16))
                .padding()
            }
        }
        .toolbar {
            ToolbarItemGroup(placement: .topBarTrailing) {
                Button {
                    mapMode.toggle()
                } label: {
                    Image(systemName: mapMode ? "camera" : "map")
                }
                .accessibilityLabel("Toggle camera and map mode")

                Button {
                    showSettings = true
                } label: {
                    Image(systemName: "slider.horizontal.3")
                }
                .accessibilityLabel("Open settings")
            }
        }
        .sheet(isPresented: $showSettings) {
            NavigationStack {
                SettingsView(configuration: $cameraViewModel.configuration,
                             routePreference: $navigationViewModel.routePreference)
            }
        }
        .onChange(of: cameraViewModel.configuration.voiceGuidanceEnabled) { enabled in
            navigationViewModel.voiceGuidanceEnabled = enabled
        }
        .task {
            cameraViewModel.start()
            navigationViewModel.start()
            navigationViewModel.voiceGuidanceEnabled = cameraViewModel.configuration.voiceGuidanceEnabled
        }
        .onDisappear {
            cameraViewModel.stop()
        }
    }

    private var statusBar: some View {
        HStack {
            VStack(alignment: .leading) {
                Text(navigationViewModel.model.nextInstruction.isEmpty ? "Follow route" : navigationViewModel.model.nextInstruction)
                    .font(.headline)
                Text("ETA \(navigationViewModel.model.etaDisplay)")
                    .font(.caption)
            }
            Spacer()
            VStack(alignment: .trailing) {
                Text(navigationViewModel.model.currentSpeedKPH.map { "\(Int($0)) km/h" } ?? "--")
                    .font(.title3.bold())
                Text("Limit \(Int(navigationViewModel.model.speedLimitKPH ?? 0))")
                    .foregroundStyle((navigationViewModel.model.currentSpeedKPH ?? 0) > (navigationViewModel.model.speedLimitKPH ?? 1000) ? .red : .green)
                    .font(.caption)
            }
        }
        .padding(12)
        .background(.ultraThinMaterial)
        .clipShape(RoundedRectangle(cornerRadius: 14))
        .accessibilityElement(children: .combine)
        .accessibilityLabel("Driving status")
    }
}
