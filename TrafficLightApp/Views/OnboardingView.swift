import SwiftUI

struct OnboardingView: View {
    let onAccept: () -> Void

    var body: some View {
        VStack(spacing: 20) {
            Image(systemName: "car.fill")
                .font(.system(size: 44))
                .foregroundStyle(.blue)

            Text("Welcome to DriveSense")
                .font(.title.bold())

            Text("Driver remains responsible for safe operation at all times. This app provides assistive navigation and detection only.")
                .multilineTextAlignment(.center)
                .foregroundStyle(.secondary)

            Button("Accept and Continue") {
                onAccept()
            }
            .buttonStyle(.borderedProminent)
        }
        .padding(24)
    }
}
