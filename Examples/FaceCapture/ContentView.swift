import SwiftUI
import FaceCaptureKit

extension String {
    var localized: String {
        NSLocalizedString(self, comment: "")
    }
}

private enum StabilityOption: String, CaseIterable {
    case frameCount = "Stable Frames"
    case countdown = "Countdown"
}

struct ContentView: View {
    @AppStorage("captureStabilityMode") private var selectedMode: StabilityOption = .countdown
    @AppStorage("captureFrameCount") private var frameCount: Int = 3
    @AppStorage("captureCountdownSeconds") private var countdownSeconds: Int = 3

    @State private var faceCaptureModel = FaceCaptureModel(
        verificationService: LiveAgeVerificationService(
            // TODO: Replace with your actual backend endpoint URL
            endpointURL: URL(string: "https://your-backend.example.com/api/verify-age")!
        ),
        stabilityMode: .countdown(seconds: 3)
    )

    var body: some View {
        NavigationStack {
            FaceCaptureView(model: faceCaptureModel) { status, retry in
                CaptureResultView(
                    status: status,
                    capturedImageData: faceCaptureModel.capturedImageData,
                    onRetry: retry
                )
            }
            .navigationTitle("Age Recognition")
            .navigationBarTitleDisplayMode(.inline)
        }
        .safeAreaInset(edge: .bottom) {
            controlPanel
        }
        .onAppear { applyMode() }
        .onChange(of: selectedMode) { applyMode() }
        .onChange(of: frameCount) { applyMode() }
        .onChange(of: countdownSeconds) { applyMode() }
    }

    private var controlPanel: some View {
        VStack(spacing: 12) {
            Picker("Stability Mode", selection: $selectedMode) {
                ForEach(StabilityOption.allCases, id: \.self) { option in
                    Text(option.rawValue.localized).tag(option)
                }
            }
            .pickerStyle(.segmented)

            HStack {
                if selectedMode == .frameCount {
                    Label("Frames", systemImage: "square.3.layers.3d")
                    Spacer()
                    Text("\(frameCount)").monospacedDigit().frame(minWidth: 28)
                    Stepper("", value: $frameCount, in: 1...24).labelsHidden()
                } else {
                    Label("Seconds", systemImage: "timer")
                    Spacer()
                    Text("\(countdownSeconds)").monospacedDigit().frame(minWidth: 28)
                    Stepper("", value: $countdownSeconds, in: 1...5).labelsHidden()
                }
            }
            .font(.subheadline)
            .animation(.easeInOut(duration: 0.2), value: selectedMode)
        }
        .padding()
        .background(.regularMaterial)
    }

    private func applyMode() {
        let mode: CaptureStabilityMode = selectedMode == .frameCount
            ? .frameCount(frameCount)
            : .countdown(seconds: countdownSeconds)
        faceCaptureModel.stabilityMode = mode
        faceCaptureModel.reset()
    }
}

// MARK: - Custom result view (demonstrates FaceCaptureView result: init)

private struct CaptureResultView: View {
    let status: VerificationStatus
    let capturedImageData: Data?
    let onRetry: () -> Void

    var body: some View {
        VStack(spacing: 24) {
            if let data = capturedImageData, let image = UIImage(data: data) {
                ZStack(alignment: .bottomTrailing) {
                    Image(uiImage: image)
                        .resizable()
                        .scaledToFit()
                        .frame(width: 150)
                        .clipShape(RoundedRectangle(cornerRadius: 12))
                        .overlay(
                            RoundedRectangle(cornerRadius: 12)
                                .stroke(.white.opacity(0.4), lineWidth: 1)
                        )
                        .padding(.horizontal, 32)

                    VerificationResultIcon(verificationStatus: status)
                        .padding(12)
                }
            }

            VerificationResultLabel(verificationStatus: status)

            Button("Try Again", action: onRetry)
                .buttonStyle(.borderedProminent)
        }
        .padding()
        .frame(maxWidth: .infinity, maxHeight: .infinity)
        .background(.ultraThinMaterial)
    }
}

#Preview {
    ContentView()
}
