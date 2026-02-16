import MapKit
import SwiftUI

struct MapView: View {
    @ObservedObject var navigationViewModel: NavigationViewModel
    @ObservedObject var mapViewModel: MapViewModel

    var body: some View {
        Map(position: $mapViewModel.cameraPosition) {
            if let destination = navigationViewModel.model.destination {
                Marker(destination.name ?? "Destination", coordinate: destination.placemark.coordinate)
                    .tint(.blue)
            }

            if let route = navigationViewModel.route {
                MapPolyline(route.polyline)
                    .stroke(.blue, lineWidth: 5)
            }
        }
        .onReceive(navigationViewModel.locationManager.$location) { location in
            mapViewModel.focus(on: location?.coordinate)
        }
    }
}
