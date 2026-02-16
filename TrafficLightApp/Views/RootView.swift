import SwiftUI

struct RootView: View {
    @AppStorage("onboardingAccepted") private var onboardingAccepted = false

    var body: some View {
        TabView {
            NavigationStack {
                DriveAssistView()
                    .navigationTitle("Drive Assist")
            }
            .tabItem {
                Label("Assist", systemImage: "car.rear.and.tire.marks")
            }

            NavigationStack {
                NavigationView()
                    .navigationTitle("Navigation")
            }
            .tabItem {
                Label("Navigate", systemImage: "map")
            }

            DashboardView(viewModel: DashboardViewModel())
                .tabItem {
                    Label("Signals", systemImage: "trafficlight")
                }
        }
        .sheet(isPresented: onboardingPresentationBinding) {
            OnboardingView {
                onboardingAccepted = true
            }
            .interactiveDismissDisabled(true)
        }
    }

    private var onboardingPresentationBinding: Binding<Bool> {
        Binding(get: { !onboardingAccepted }, set: { value in
            onboardingAccepted = !value
        })
    }
}
