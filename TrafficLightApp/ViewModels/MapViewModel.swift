import Foundation
import MapKit

@MainActor
final class MapViewModel: ObservableObject {
    @Published var cameraPosition: MapCameraPosition = .automatic
    @Published var isCameraInPictureInPicture = true

    func focus(on coordinate: CLLocationCoordinate2D?) {
        guard let coordinate else { return }
        cameraPosition = .region(MKCoordinateRegion(center: coordinate,
                                                    span: MKCoordinateSpan(latitudeDelta: 0.012, longitudeDelta: 0.012)))
    }

    func togglePictureInPicture() {
        isCameraInPictureInPicture.toggle()
    }
}
