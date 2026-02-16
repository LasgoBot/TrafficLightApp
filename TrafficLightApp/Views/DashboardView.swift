import MapKit
import SwiftUI

struct DashboardView: View {
    @StateObject var viewModel: DashboardViewModel
    @State private var cameraPosition: MapCameraPosition = .automatic

    var body: some View {
        NavigationStack {
            ZStack {
                LuxuryTheme.backgroundGradient.ignoresSafeArea()

                ScrollView {
                    VStack(spacing: 16) {
                        headerChip

                        mapSection
                            .frame(height: 260)
                            .clipShape(RoundedRectangle(cornerRadius: 20))
                            .overlay(alignment: .topTrailing) {
                                Button {
                                    updateCamera()
                                } label: {
                                    Label("Recenter", systemImage: "location.fill")
                                        .font(.caption.weight(.semibold))
                                }
                                .buttonStyle(.borderedProminent)
                                .tint(LuxuryTheme.accent)
                                .padding(12)
                            }

                        SignalCountdownCard(signal: viewModel.signal, state: viewModel.state)
                        RouteProgressCard(routeProgress: viewModel.routeProgress)
                        destinationButtons
                    }
                    .padding()
                }
            }
            .navigationTitle("Traffic Light Assist")
            .toolbarTitleDisplayMode(.inline)
        }
    }

    private var headerChip: some View {
        HStack {
            Label("Mode: \(viewModel.predictionModeLabel)", systemImage: "cpu")
                .font(.caption.weight(.semibold))
                .foregroundStyle(.white)
            Spacer()
            Label("Live", systemImage: "dot.radiowaves.left.and.right")
                .font(.caption.weight(.semibold))
                .foregroundStyle(.green)
        }
        .padding(10)
        .background(Color.white.opacity(0.08))
        .clipShape(RoundedRectangle(cornerRadius: 12))
    }

    private var mapSection: some View {
        Map(position: $cameraPosition) {
            if let signal = viewModel.signal {
                Marker(signal.intersectionName, coordinate: signal.coordinate)
                    .tint(color(for: signal.phase))
            }
            if let destination = viewModel.selectedDestination {
                Marker(destination.name ?? "Destination", coordinate: destination.placemark.coordinate)
                    .tint(LuxuryTheme.accent)
            }
        }
        .onAppear { updateCamera() }
    }

    private var destinationButtons: some View {
        HStack(spacing: 12) {
            quickDestinationButton(title: "Home", latitude: 37.3349, longitude: -122.0090, prominent: true)
            quickDestinationButton(title: "Work", latitude: 37.7749, longitude: -122.4194, prominent: false)
        }
    }

    private func quickDestinationButton(title: String, latitude: Double, longitude: Double, prominent: Bool) -> some View {
        Button(title) {
            let item = MKMapItem(placemark: MKPlacemark(coordinate: CLLocationCoordinate2D(latitude: latitude,
                                                                                           longitude: longitude)))
            item.name = title
            viewModel.setDestination(item)
            updateCamera()
        }
        .buttonStyle(prominent ? .borderedProminent : .bordered)
        .tint(prominent ? LuxuryTheme.accent : .white)
        .foregroundStyle(prominent ? .black : .white)
        .controlSize(.large)
    }

    private func updateCamera() {
        if let coordinate = viewModel.signal?.coordinate {
            cameraPosition = .region(MKCoordinateRegion(center: coordinate,
                                                        span: MKCoordinateSpan(latitudeDelta: 0.008,
                                                                               longitudeDelta: 0.008)))
        }
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
