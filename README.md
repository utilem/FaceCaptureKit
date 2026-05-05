# FaceCaptureKit

A SwiftUI package for real-time face capture and age verification using the [Yoti Face Capture SDK](https://github.com/getyoti/yoti-face-capture-ios). The package provides a ready-to-use camera view with face guidance overlay, automatic face analysis, and a pluggable verification service protocol.

## Requirements

- iOS 17+
- Swift 6.3+
- Xcode 16+

## Installation

Add the package to your Xcode project via **File > Add Package Dependencies** and enter the repository URL. The package itself depends on `yoti-face-capture-ios`, which is resolved automatically.

In your `Package.swift`:

```swift
dependencies: [
    .package(url: "<repository-url>", from: "<version>")
]
```

Add `FaceCaptureKit` to your target's dependencies:

```swift
.target(
    name: "MyApp",
    dependencies: ["FaceCaptureKit"]
)
```

## Usage

### Basic integration

```swift
import SwiftUI
import FaceCaptureKit

struct ContentView: View {
    @State private var model = FaceCaptureModel(
        verificationService: LiveAgeVerificationService(
            endpointURL: URL(string: "https://your-backend.example.com/api/verify-age")!
        )
    )

    var body: some View {
        FaceCaptureView(model: model)
    }
}
```

`FaceCaptureView` handles camera permission requests, face detection, image capture, and result presentation. No additional setup is required.

### Capture stability mode

To avoid blurry images caused by camera movement, `FaceCaptureModel` requires a stable face before capturing. Two strategies are available via `CaptureStabilityMode`:

```swift
// N consecutive valid frames must be detected before the image is sent (default: 3).
FaceCaptureModel(verificationService: ..., stabilityMode: .frameCount(3))

// A visible countdown runs while the face is held still; the image is captured when it reaches zero.
FaceCaptureModel(verificationService: ..., stabilityMode: .countdown(seconds: 3))
```

The stability mode can be changed at runtime without restarting the camera:

```swift
model.stabilityMode = .frameCount(5)
model.reset()
```

During a countdown, `model.countdown` contains the current value (`Int?`) and can be observed to build custom overlays. `FaceCaptureKit` renders the countdown automatically with a scale/fade animation. If the face moves or an analysis error occurs, the countdown is cancelled and restarts on the next stable frame.

### Custom verification service

Implement `AgeVerificationService` to connect your own backend:

```swift
import FaceCaptureKit

struct MyVerificationService: AgeVerificationService {
    func verify(imageData: Data) async throws -> AgeVerificationResult {
        // Send imageData to your API and return the result
        let result = try await myAPI.verify(imageData: imageData)
        return AgeVerificationResult(
            isVerified: result.isVerified,
            estimatedAge: result.age,
            message: result.message
        )
    }
}
```

The `AgeVerificationResult` your service returns must conform to this structure:

```swift
public struct AgeVerificationResult: Codable, Sendable {
    public let isVerified: Bool
    public let estimatedAge: Int?   // optional
    public let message: String?     // optional, shown below the status label
}
```

The built-in `LiveAgeVerificationService` POSTs the captured JPEG to your endpoint and decodes a JSON response matching the same structure (`verified`, `estimatedAge`, `message`).

## Examples

The `Examples/FaceCapture` directory contains a ready-to-run iOS app that demonstrates `FaceCaptureKit` in action. It shows the live camera view and lets you switch between stability modes (frame count / countdown) and adjust their parameters at runtime via a control panel at the bottom of the screen.

To run it, open `Examples/FaceCapture.xcodeproj` in Xcode, replace the placeholder endpoint URL in `ContentView.swift` with your backend URL, and run the app on a physical device (camera required).

## How it works

1. The camera opens and Yoti analyzes each frame continuously.
2. A face guidance overlay displays real-time hints (e.g. "Align your face here", "Face not centered").
3. Once the configured stability threshold is met (consecutive valid frames or countdown), the image is captured and passed to the verification service.
4. A result sheet shows the verification outcome, estimated age, and a retry option.

Face analysis validates: eye openness, environment brightness, face size, centering, stability, and orientation. Which checks are active can be configured by subclassing or forking `CameraViewController`.

## Data Protection (GDPR / DSGVO)

Facial images are personal data under Art. 4 GDPR. Depending on how the backend derives information from the image, the data may additionally qualify as biometric special category data (Art. 9 GDPR).

The integrator acts as data controller and is responsible for establishing a legal basis, informing users, ensuring data minimisation on the backend, and — where applicable — conducting a Data Protection Impact Assessment (Art. 35 GDPR) prior to deployment.

This package provides no consent UI, retention enforcement, or deletion mechanism. *Nothing in this documentation constitutes legal advice.*

## Security Considerations

> **Important:** `FaceCaptureKit` is a face capture and image submission library. It does **not** provide presentation attack detection (PAD) or liveness detection of any kind.

### No liveness detection

The `yoti-face-capture-ios` SDK used by this package validates geometric face quality — centering, size, eye openness, stability, and orientation — but does not distinguish a live person from a photograph, video, or animated image played in front of the camera. A recording of a valid face will pass all capture checks successfully.

Any backend service connected via `AgeVerificationService` is responsible for implementing anti-spoofing measures appropriate to the required assurance level.

### Regulatory compliance

Yoti offers a certified, server-side identity and age verification service that includes liveness detection and biometric matching. That commercial service has undergone regulatory assessments in various jurisdictions. **The open-source `yoti-face-capture-ios` SDK — and by extension this package — is not that service and carries none of its certifications or compliance guarantees.**

If your use case requires regulatory compliance (e.g. EU Digital Services Act age verification, eIDAS, or equivalent national frameworks), you must:

- Use a certified identity verification provider that includes server-side liveness detection
- Consult current guidance from the relevant regulatory authority — compliance requirements change and no documentation in this package should be treated as legal advice
- Review Yoti's current certification status directly at [yoti.com](https://www.yoti.com)

### Recommendations for production use

- Implement server-side liveness detection in your `AgeVerificationService` backend
- Rate-limit and monitor verification requests to detect replay attacks
- Do not rely solely on client-side capture quality as a security signal

## Localization

The package ships with English (default) and German (`de`) localizations for all user-visible strings. The localization is resolved against the package's own bundle, so strings appear correctly regardless of the host app's bundle.

To add another language, open `Sources/FaceCaptureKit/Resources/Localizable.xcstrings` in Xcode and add translations for the existing keys.

## Architecture

| Type | Role |
|---|---|
| `FaceCaptureView` | Public SwiftUI entry point |
| `FaceCaptureModel` | `@Observable` view model, owns state and orchestrates capture/verification flow |
| `AgeVerificationService` | Protocol — implement to connect any backend |
| `LiveAgeVerificationService` | Default HTTP implementation (POST + JSON decode) |
| `CameraViewController` | `UIViewControllerRepresentable` wrapper around `YotiFaceCapture` |
| `CameraOverlayView` | Face frame graphic and animated hint badge |
| `VerificationResultView` | Result sheet with icon, status, estimated age, and retry button |

## License

FaceCaptureKit is released under the MIT License. See [LICENSE](LICENSE) for details.

The [Yoti Face Capture iOS SDK](https://github.com/getyoti/yoti-face-capture-ios) is used as a package dependency and is distributed under its own MIT License (Copyright © 2020 Yoti Ltd.). The full third-party notice is included in the [LICENSE](LICENSE) file as required by the MIT terms.
