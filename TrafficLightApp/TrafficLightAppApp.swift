import SwiftUI
import SwiftData

@main
struct TrafficLightAppApp: App {
    @StateObject private var dataController = DataController.shared
    
    var body: some Scene {
        WindowGroup {
            RootView()
                .environmentObject(dataController)
        }
        .modelContainer(dataController.container)
    }
}
