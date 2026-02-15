import MapKit
import SwiftUI

struct NavigationView: View {
    @StateObject var navigationViewModel = NavigationViewModel()
    @StateObject var mapViewModel = MapViewModel()
    @State private var showSearch = false

    var body: some View {
        ZStack {
            MapView(navigationViewModel: navigationViewModel, mapViewModel: mapViewModel)
                .ignoresSafeArea()

            VStack(spacing: 10) {
                topBar
                Spacer()
                bottomBar
            }
            .padding()
        }
        .toolbar {
            ToolbarItem(placement: .topBarTrailing) {
                Button {
                    showSearch = true
                } label: {
                    Image(systemName: "magnifyingglass")
                }
            }
        }
        .sheet(isPresented: $showSearch) {
            destinationSheet
        }
        .task {
            navigationViewModel.start()
        }
        .onReceive(navigationViewModel.locationManager.$location) { location in
            guard let coordinate = location?.coordinate else { return }
            Task { await navigationViewModel.rerouteIfNeeded(currentCoordinate: coordinate) }
            navigationViewModel.updateSpeed()
        }
    }

    private var topBar: some View {
        HStack {
            VStack(alignment: .leading) {
                Text(navigationViewModel.model.nextInstruction.isEmpty ? "Head to destination" : navigationViewModel.model.nextInstruction)
                    .font(.headline)
                Text("in \(Int(navigationViewModel.model.nextInstructionDistanceMeters)) m")
                    .font(.caption)
            }
            Spacer()
            Text(navigationViewModel.model.currentSpeedKPH.map { "\(Int($0)) km/h" } ?? "--")
                .font(.title3.bold())
        }
        .padding(12)
        .background(.ultraThinMaterial)
        .clipShape(RoundedRectangle(cornerRadius: 14))
    }

    private var bottomBar: some View {
        HStack {
            VStack(alignment: .leading) {
                Text("ETA \(navigationViewModel.model.etaDisplay)")
                Text("Remaining \(Int(navigationViewModel.model.remainingDistanceMeters / 1000)) km")
                    .font(.caption)
            }
            Spacer()
            Text("Limit \(Int(navigationViewModel.model.speedLimitKPH ?? 0))")
                .foregroundStyle((navigationViewModel.model.currentSpeedKPH ?? 0) > (navigationViewModel.model.speedLimitKPH ?? 1000) ? .red : .green)
                .font(.headline)
        }
        .padding(12)
        .background(.ultraThinMaterial)
        .clipShape(RoundedRectangle(cornerRadius: 14))
    }

    private var destinationSheet: some View {
        NavigationStack {
            List {
                TextField("Search destination", text: $navigationViewModel.searchQuery)
                    .onChange(of: navigationViewModel.searchQuery) {
                        navigationViewModel.updateSearch()
                    }

                ForEach(navigationViewModel.searchResults, id: \.self) { result in
                    Button(result) {
                        let mapItem = MKMapItem(placemark: MKPlacemark(coordinate: CLLocationCoordinate2D(latitude: 37.7749,
                                                                                                         longitude: -122.4194)))
                        mapItem.name = result
                        Task {
                            await navigationViewModel.setDestination(mapItem)
                            showSearch = false
                        }
                    }
                }
            }
            .navigationTitle("Navigate")
        }
    }
}
