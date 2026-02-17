import SwiftUI
import Combine

/// Example view demonstrating integration of the Telematics system
struct TelematicsExampleView: View {
    @StateObject private var viewModel = TelematicsExampleViewModel()
    
    var body: some View {
        NavigationView {
            VStack(spacing: 20) {
                // Status Section
                GroupBox("Telematics Status") {
                    VStack(alignment: .leading, spacing: 10) {
                        HStack {
                            Text("Monitoring:")
                            Spacer()
                            Text(viewModel.telematicsService.isMonitoring ? "Active" : "Inactive")
                                .foregroundColor(viewModel.telematicsService.isMonitoring ? .green : .red)
                        }
                        
                        HStack {
                            Text("Background Mode:")
                            Spacer()
                            Text(viewModel.backgroundManager.isBackgroundEnabled ? "Enabled" : "Disabled")
                                .foregroundColor(viewModel.backgroundManager.isBackgroundEnabled ? .green : .red)
                        }
                        
                        if let prediction = viewModel.telematicsService.lastPrediction {
                            Divider()
                            VStack(alignment: .leading, spacing: 5) {
                                Text("Last Prediction")
                                    .font(.headline)
                                Text("Signal: \(prediction.nodeID)")
                                    .font(.caption)
                                Text("Confidence: \(Int(prediction.confidence * 100))%")
                                    .font(.caption)
                                Text("Cycle: \(Int(prediction.cycleLength))s")
                                    .font(.caption)
                            }
                        }
                    }
                    .padding()
                }
                
                // Controls
                VStack(spacing: 10) {
                    Button(action: {
                        if viewModel.telematicsService.isMonitoring {
                            viewModel.telematicsService.stopMonitoring()
                        } else {
                            viewModel.telematicsService.startMonitoring()
                        }
                    }) {
                        Text(viewModel.telematicsService.isMonitoring ? "Stop Monitoring" : "Start Monitoring")
                            .frame(maxWidth: .infinity)
                            .padding()
                            .background(viewModel.telematicsService.isMonitoring ? Color.red : Color.blue)
                            .foregroundColor(.white)
                            .cornerRadius(10)
                    }
                    
                    Button(action: {
                        if viewModel.backgroundManager.isBackgroundEnabled {
                            viewModel.backgroundManager.disableBackgroundMode()
                        } else {
                            viewModel.backgroundManager.enableBackgroundMode()
                        }
                    }) {
                        Text(viewModel.backgroundManager.isBackgroundEnabled ? "Disable Background" : "Enable Background")
                            .frame(maxWidth: .infinity)
                            .padding()
                            .background(viewModel.backgroundManager.isBackgroundEnabled ? Color.orange : Color.green)
                            .foregroundColor(.white)
                            .cornerRadius(10)
                    }
                }
                .padding(.horizontal)
                
                // Event Log
                GroupBox("Recent Events") {
                    ScrollView {
                        LazyVStack(alignment: .leading, spacing: 5) {
                            ForEach(viewModel.events.indices, id: \.self) { index in
                                Text(viewModel.events[index])
                                    .font(.caption)
                                    .padding(.vertical, 2)
                            }
                        }
                    }
                    .frame(maxHeight: 200)
                }
                .padding(.horizontal)
                
                Spacer()
            }
            .navigationTitle("Telematics Demo")
        }
    }
}

@MainActor
final class TelematicsExampleViewModel: ObservableObject {
    let telematicsService = TelematicsService()
    let backgroundManager = BackgroundTelematicsManager()
    
    @Published var events: [String] = []
    
    private var cancellables = Set<AnyCancellable>()
    
    init() {
        setupEventStream()
    }
    
    private func setupEventStream() {
        telematicsService.stopWaitLaunchStream
            .receive(on: DispatchQueue.main)
            .sink { [weak self] event in
                self?.handleEvent(event)
            }
            .store(in: &cancellables)
    }
    
    private func handleEvent(_ event: TelematicsFlowEvent) {
        let timestamp = DateFormatter.localizedString(from: Date(), dateStyle: .none, timeStyle: .medium)
        
        switch event {
        case .stoppedAtSignal(let node, _):
            addEvent("[\(timestamp)] Stopped at signal: \(node.id)")
            
        case .stoppedInTraffic(let location):
            addEvent("[\(timestamp)] Stopped in traffic at \(String(format: "%.4f", location.latitude)), \(String(format: "%.4f", location.longitude))")
            
        case .waiting(let location):
            addEvent("[\(timestamp)] Waiting at \(String(format: "%.4f", location.coordinate.latitude))")
            
        case .launchedFromSignal(let node, let prediction, _):
            addEvent("[\(timestamp)] Launched from \(node.id) - Next green in \(Int(prediction.cycleLength))s")
            
        case .launched(let location, _):
            addEvent("[\(timestamp)] Launched from \(String(format: "%.4f", location.latitude))")
            
        case .moving(let speedKPH):
            if speedKPH > 20 {
                addEvent("[\(timestamp)] Moving at \(Int(speedKPH)) km/h")
            }
        }
    }
    
    private func addEvent(_ event: String) {
        events.insert(event, at: 0)
        if events.count > 50 {
            events.removeLast()
        }
    }
}

struct TelematicsExampleView_Previews: PreviewProvider {
    static var previews: some View {
        TelematicsExampleView()
    }
}
