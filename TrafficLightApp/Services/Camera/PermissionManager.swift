import AVFoundation
import CoreLocation
import Foundation

@MainActor
final class PermissionManager: ObservableObject {
    @Published var cameraAuthorized = false
    @Published var locationAuthorized = false

    func requestAllPermissions(locationService: LocationService) async {
        cameraAuthorized = await requestCameraPermission()
        locationService.requestAccess()
        let status = locationService.authorizationStatus
        locationAuthorized = status == .authorizedAlways || status == .authorizedWhenInUse
    }

    private func requestCameraPermission() async -> Bool {
        switch AVCaptureDevice.authorizationStatus(for: .video) {
        case .authorized:
            return true
        case .notDetermined:
            return await AVCaptureDevice.requestAccess(for: .video)
        case .denied, .restricted:
            return false
        @unknown default:
            return false
        }
    }
}
