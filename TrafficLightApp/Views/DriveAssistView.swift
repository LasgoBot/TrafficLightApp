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

                CameraOverlayView(detections: cameraViewModel.detectionResults,
                                  trafficLightDetection: cameraViewModel.trafficLightDetection,
                                  countdown: cameraViewModel.countdown)
                    .ignoresSafeArea()

                if mapViewModel.isCameraInPictureInPicture {
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
        }
        .toolbar {
            ToolbarItemGroup(placement: .topBarTrailing) {
                Button {
                    mapMode.toggle()
                } label: {
                    Image(systemName: mapMode ? "camera" : "map")
                }

                Button {
                    showSettings = true
                } label: {
                    Image(systemName: "slider.horizontal.3")
                }
            }
        }
        .sheet(isPresented: $showSettings) {
            NavigationStack {
                SettingsView(configuration: $cameraViewModel.configuration,
                             routePreference: $navigationViewModel.routePreference)
            }
        }
        .task {
            cameraViewModel.start()
            navigationViewModel.start()
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
    }
}
