import SwiftUI
import Combine

/// Example view demonstrating integration of the Telematics system
struct TelematicsExampleView: View {
    @StateObject private var telematicsService = TelematicsService()
    @StateObject private var backgroundManager = BackgroundTelematicsManager()
    
    @State private var events: [String] = []
    @State private var isMonitoring = false
    @State private var cancellables = Set<AnyCancellable>()
    
    var body: some View {
        NavigationView {
            VStack(spacing: 20) {
                // Status Section
                GroupBox("Telematics Status") {
                    VStack(alignment: .leading, spacing: 10) {
                        HStack {
                            Text("Monitoring:")
                            Spacer()
                            Text(telematicsService.isMonitoring ? "Active" : "Inactive")
                                .foregroundColor(telematicsService.isMonitoring ? .green : .red)
                        }
                        
                        HStack {
                            Text("Background Mode:")
                            Spacer()
                            Text(backgroundManager.isBackgroundEnabled ? "Enabled" : "Disabled")
                                .foregroundColor(backgroundManager.isBackgroundEnabled ? .green : .red)
                        }
                        
                        if let prediction = telematicsService.lastPrediction {
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
                        if telematicsService.isMonitoring {
                            telematicsService.stopMonitoring()
                        } else {
                            telematicsService.startMonitoring()
                        }
                    }) {
                        Text(telematicsService.isMonitoring ? "Stop Monitoring" : "Start Monitoring")
                            .frame(maxWidth: .infinity)
                            .padding()
                            .background(telematicsService.isMonitoring ? Color.red : Color.blue)
                            .foregroundColor(.white)
                            .cornerRadius(10)
                    }
                    
                    Button(action: {
                        if backgroundManager.isBackgroundEnabled {
                            backgroundManager.disableBackgroundMode()
                        } else {
                            backgroundManager.enableBackgroundMode()
                        }
                    }) {
                        Text(backgroundManager.isBackgroundEnabled ? "Disable Background" : "Enable Background")
                            .frame(maxWidth: .infinity)
                            .padding()
                            .background(backgroundManager.isBackgroundEnabled ? Color.orange : Color.green)
                            .foregroundColor(.white)
                            .cornerRadius(10)
                    }
                }
                .padding(.horizontal)
                
                // Event Log
                GroupBox("Recent Events") {
                    ScrollView {
                        LazyVStack(alignment: .leading, spacing: 5) {
                            ForEach(events.indices, id: \.self) { index in
                                Text(events[index])
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
            .onAppear {
                setupEventStream()
            }
        }
    }
    
    private func setupEventStream() {
        telematicsService.stopWaitLaunchStream
            .receive(on: DispatchQueue.main)
            .sink { event in
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
            .store(in: &cancellables)
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
