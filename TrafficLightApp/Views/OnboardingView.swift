import SwiftUI

struct OnboardingView: View {
    let onAccept: () -> Void

    var body: some View {
        VStack(spacing: 20) {
            Image(systemName: "car.fill")
                .font(.system(size: 44))
                .foregroundStyle(.blue)
                .accessibilityHidden(true)

            Text(String(localized: "onboarding.title"))
                .font(.title.bold())

            Text(String(localized: "onboarding.disclaimer"))
                .multilineTextAlignment(.center)
                .foregroundStyle(.secondary)

            Button("Accept and Continue") {
                onAccept()
            }
            .buttonStyle(.borderedProminent)
            .accessibilityLabel("Accept disclaimer and continue")
        }
        .padding(24)
    }
}
