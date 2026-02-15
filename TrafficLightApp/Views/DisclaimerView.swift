import SwiftUI

struct DisclaimerView: View {
    let onContinue: () -> Void

    var body: some View {
        VStack(spacing: 16) {
            Image(systemName: "exclamationmark.shield.fill")
                .font(.system(size: 50))
                .foregroundStyle(.yellow)
            Text("Driver Responsibility")
                .font(.title.bold())
            Text("This app is assistive only. Always obey real-world traffic laws, roadway signs, and road conditions. Do not rely solely on automated detections.")
                .multilineTextAlignment(.center)
                .foregroundStyle(.secondary)
            Button("I Understand") {
                onContinue()
            }
            .buttonStyle(.borderedProminent)
        }
        .padding()
    }
}
