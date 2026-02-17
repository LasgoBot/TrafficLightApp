import SwiftUI
import SwiftData

struct ProductionDemoView: View {
    @StateObject private var simulationManager = SimulationManager()
    @EnvironmentObject private var dataController: DataController
    @State private var showingNodeList = false
    
    var body: some View {
        NavigationView {
            ScrollView {
                VStack(spacing: 24) {
                    // Header
                    VStack(spacing: 8) {
                        Text("Production Demo")
                            .font(.largeTitle)
                            .bold()
                        Text("SwiftData • Dynamic Island • Simulation")
                            .font(.subheadline)
                            .foregroundColor(.secondary)
                    }
                    .padding(.top)
                    
                    // Module 1: SwiftData Persistence
                    GroupBox {
                        VStack(alignment: .leading, spacing: 12) {
                            HStack {
                                Image(systemName: "cylinder.fill")
                                    .foregroundColor(.blue)
                                Text("SwiftData Persistence")
                                    .font(.headline)
                            }
                            
                            Divider()
                            
                            HStack {
                                Text("Saved Nodes:")
                                    .foregroundColor(.secondary)
                                Spacer()
                                Text("\(dataController.getAllNodes().count)")
                                    .font(.title3)
                                    .bold()
                            }
                            
                            Button(action: { showingNodeList = true }) {
                                Label("View All Nodes", systemImage: "list.bullet")
                                    .frame(maxWidth: .infinity)
                                    .padding(.vertical, 8)
                                    .background(Color.blue.opacity(0.1))
                                    .cornerRadius(8)
                            }
                            .buttonStyle(PlainButtonStyle())
                        }
                        .padding()
                    }
                    
                    // Module 2: Dynamic Island
                    GroupBox {
                        VStack(alignment: .leading, spacing: 12) {
                            HStack {
                                Image(systemName: "apps.iphone")
                                    .foregroundColor(.purple)
                                Text("Dynamic Island")
                                    .font(.headline)
                            }
                            
                            Divider()
                            
                            if #available(iOS 16.2, *) {
                                VStack(alignment: .leading, spacing: 8) {
                                    HStack {
                                        Text("Status:")
                                            .foregroundColor(.secondary)
                                        Spacer()
                                        Text(LiveActivityManager.shared.isActivityActive ? "Active" : "Inactive")
                                            .foregroundColor(LiveActivityManager.shared.isActivityActive ? .green : .secondary)
                                    }
                                    
                                    Text("Live Activity will automatically start when you stop at a traffic signal")
                                        .font(.caption)
                                        .foregroundColor(.secondary)
                                        .padding(.vertical, 4)
                                    
                                    // Demo button
                                    Button(action: { startDemoActivity() }) {
                                        Label("Demo Dynamic Island", systemImage: "sparkles")
                                            .frame(maxWidth: .infinity)
                                            .padding(.vertical, 8)
                                            .background(Color.purple.opacity(0.1))
                                            .cornerRadius(8)
                                    }
                                    .buttonStyle(PlainButtonStyle())
                                }
                            } else {
                                Text("Dynamic Island requires iOS 16.2+")
                                    .font(.caption)
                                    .foregroundColor(.secondary)
                                    .padding(.vertical, 8)
                            }
                        }
                        .padding()
                    }
                    
                    // Module 3: Simulation
                    GroupBox {
                        VStack(alignment: .leading, spacing: 12) {
                            HStack {
                                Image(systemName: "play.circle.fill")
                                    .foregroundColor(.green)
                                Text("Drive Simulation")
                                    .font(.headline)
                            }
                            
                            Divider()
                            
                            if simulationManager.isSimulating {
                                VStack(alignment: .leading, spacing: 8) {
                                    HStack {
                                        ProgressView()
                                            .scaleEffect(0.8)
                                        Text(simulationManager.currentSimulationStep)
                                            .font(.subheadline)
                                    }
                                    
                                    Button(action: { simulationManager.stopSimulation() }) {
                                        Label("Stop Simulation", systemImage: "stop.fill")
                                            .frame(maxWidth: .infinity)
                                            .padding(.vertical, 8)
                                            .background(Color.red.opacity(0.1))
                                            .cornerRadius(8)
                                    }
                                    .buttonStyle(PlainButtonStyle())
                                }
                            } else {
                                VStack(alignment: .leading, spacing: 8) {
                                    Text("Simulates a complete drive cycle:")
                                        .font(.subheadline)
                                        .foregroundColor(.secondary)
                                    
                                    VStack(alignment: .leading, spacing: 4) {
                                        Label("Approach intersection", systemImage: "car.fill")
                                            .font(.caption)
                                        Label("Stop for 40 seconds", systemImage: "stop.fill")
                                            .font(.caption)
                                        Label("Launch on green", systemImage: "arrow.up.circle.fill")
                                            .font(.caption)
                                        Label("Save to SwiftData", systemImage: "checkmark.circle.fill")
                                            .font(.caption)
                                    }
                                    .foregroundColor(.secondary)
                                    .padding(.vertical, 4)
                                    
                                    Button(action: { simulationManager.simulateDrive() }) {
                                        Label("Start Simulation", systemImage: "play.fill")
                                            .frame(maxWidth: .infinity)
                                            .padding(.vertical, 8)
                                            .background(Color.green.opacity(0.1))
                                            .cornerRadius(8)
                                    }
                                    .buttonStyle(PlainButtonStyle())
                                }
                            }
                        }
                        .padding()
                    }
                    
                    // Simulation Log
                    if !simulationManager.simulationLog.isEmpty {
                        GroupBox("Simulation Log") {
                            ScrollView {
                                VStack(alignment: .leading, spacing: 4) {
                                    ForEach(simulationManager.simulationLog.suffix(10), id: \.self) { log in
                                        Text(log)
                                            .font(.system(.caption, design: .monospaced))
                                            .foregroundColor(.secondary)
                                    }
                                }
                            }
                            .frame(maxHeight: 200)
                        }
                    }
                }
                .padding()
            }
            .navigationTitle("Production Modules")
            .sheet(isPresented: $showingNodeList) {
                NodeListView()
                    .environmentObject(dataController)
            }
        }
    }
    
    @available(iOS 16.2, *)
    private func startDemoActivity() {
        let manager = LiveActivityManager.shared
        manager.startActivity(
            intersectionName: "Demo Intersection",
            geoID: "demo_001",
            initialState: .red,
            countdown: 15,
            targetSpeed: 30
        )
        
        // Auto-update countdown with proper cleanup
        var countdown = 15
        let timer = Timer.scheduledTimer(withTimeInterval: 1.0, repeats: true) { timer in
            countdown -= 1
            if countdown > 0 {
                manager.updateActivity(
                    state: countdown > 3 ? .red : .yellow,
                    countdown: countdown,
                    targetSpeed: 30
                )
            } else {
                manager.updateActivity(state: .green, countdown: 0, targetSpeed: 35)
                timer.invalidate()
                
                // End activity after 3 seconds
                DispatchQueue.main.asyncAfter(deadline: .now() + 3) {
                    manager.endActivity()
                }
            }
        }
        
        // Store timer reference to ensure proper cleanup
        // In production, store this in a @State or class property for lifecycle management
        _ = timer // Timer is automatically retained by RunLoop
    }
}

// Node List View
struct NodeListView: View {
    @EnvironmentObject private var dataController: DataController
    @Environment(\.dismiss) private var dismiss
    
    var body: some View {
        NavigationView {
            List {
                let nodes = dataController.getAllNodes()
                
                if nodes.isEmpty {
                    ContentUnavailableView(
                        "No Nodes Yet",
                        systemImage: "map",
                        description: Text("Run a simulation or drive to learn traffic signals")
                    )
                } else {
                    ForEach(nodes, id: \.geoID) { node in
                        VStack(alignment: .leading, spacing: 8) {
                            Text("Node \(node.geoID.prefix(10))")
                                .font(.headline)
                            
                            HStack {
                                VStack(alignment: .leading, spacing: 4) {
                                    Label("\(node.latitude, specifier: "%.6f"), \(node.longitude, specifier: "%.6f")",
                                          systemImage: "location.fill")
                                        .font(.caption)
                                    
                                    Label("Cycle: \(Int(node.cycleDuration))s",
                                          systemImage: "clock.fill")
                                        .font(.caption)
                                }
                                
                                Spacer()
                                
                                VStack(alignment: .trailing, spacing: 4) {
                                    Text("Confidence")
                                        .font(.caption2)
                                        .foregroundColor(.secondary)
                                    Text("\(node.confidenceScore)")
                                        .font(.title3)
                                        .bold()
                                        .foregroundColor(confidenceColor(node.confidenceScore))
                                }
                            }
                        }
                        .padding(.vertical, 4)
                    }
                    .onDelete(perform: deleteNodes)
                }
            }
            .navigationTitle("Learned Nodes")
            .navigationBarTitleDisplayMode(.inline)
            .toolbar {
                ToolbarItem(placement: .navigationBarLeading) {
                    Button("Done") {
                        dismiss()
                    }
                }
                
                if !dataController.getAllNodes().isEmpty {
                    ToolbarItem(placement: .navigationBarTrailing) {
                        Button(role: .destructive) {
                            dataController.deleteAllNodes()
                        } label: {
                            Label("Clear All", systemImage: "trash")
                        }
                    }
                }
            }
        }
    }
    
    private func deleteNodes(at offsets: IndexSet) {
        let nodes = dataController.getAllNodes()
        for index in offsets {
            dataController.deleteNode(geoID: nodes[index].geoID)
        }
    }
    
    private func confidenceColor(_ score: Int) -> Color {
        switch score {
        case 0..<20: return .red
        case 20..<50: return .orange
        case 50..<80: return .yellow
        default: return .green
        }
    }
}

struct ProductionDemoView_Previews: PreviewProvider {
    static var previews: some View {
        ProductionDemoView()
            .environmentObject(DataController.shared)
    }
}
