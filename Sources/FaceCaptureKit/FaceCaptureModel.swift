//
//  FaceCaptureModel.swift
//  FaceCaptureKit
//
//  Copyright © 2026 Uwe Tilemann. All rights reserved.
//

import Foundation
import Observation

// MARK: - Stability Mode

public enum CaptureStabilityMode: Sendable {
    /// Requires N consecutive valid frames before capturing. Recommended default: 3.
    case frameCount(Int)
    /// Shows a visual countdown and captures when it reaches zero.
    case countdown(seconds: Int)
}

// MARK: - State Types

enum FaceCaptureStatus: Equatable {
    case idle
    case analyzing
    case captured
}

enum VerificationStatus {
    case idle
    case uploading
    case verified(AgeVerificationResult)
    case failed(String)

    var isTerminal: Bool {
        switch self {
        case .verified, .failed: return true
        default: return false
        }
    }

    var statusString: String {
        switch self {
        case .verified(let result):
            return result.isVerified
                ? String(localized: "Age Verified", bundle: .module)
                : String(localized: "Not Verified", bundle: .module)
        case .failed:
            return String(localized: "Verification Failed", bundle: .module)
        default:
            return ""
        }
    }
}

// MARK: - Stability State

private struct StabilityState {
    var frameCount = 0
    var countdownTask: Task<Void, Never>?
    var latestImageData: Data?

    var isInProgress: Bool { frameCount > 0 || countdownTask != nil }

    mutating func reset() {
        frameCount = 0
        countdownTask?.cancel()
        countdownTask = nil
        latestImageData = nil
    }
}

// MARK: - Model

@Observable
@MainActor
public final class FaceCaptureModel {
    private(set) var captureStatus: FaceCaptureStatus = .idle
    private(set) var verificationStatus: VerificationStatus = .idle
    private(set) var hint: String = String(localized: "Align your face here", bundle: .module)
    private(set) var isAnalysisError: Bool = false
    public var isReadyForAnalysing: Bool = true
    public private(set) var capturedImageData: Data?
    /// Current countdown value; non-nil only during an active countdown.
    public private(set) var countdown: Int? = nil

    private let verificationService: any AgeVerificationService
    public var stabilityMode: CaptureStabilityMode
    /// True while frame counting or countdown is in progress — used to suppress transient errors like blinking.
    var isStabilityInProgress: Bool { stability.isInProgress }

    private var stability = StabilityState()
    private var lastHintChangeDate: Date = .distantPast

    public init(
        verificationService: any AgeVerificationService,
        stabilityMode: CaptureStabilityMode = .frameCount(3)
    ) {
        self.verificationService = verificationService
        self.stabilityMode = stabilityMode
    }

    // Called by CameraViewController for each valid frame from Yoti
    func didReceiveValidFrame(imageData: Data) {
        guard captureStatus != .captured else { return }
        stability.latestImageData = imageData

        switch stabilityMode {
        case .frameCount(let required):
            stability.frameCount += 1
            if stability.frameCount == 1 {
                showValidFrameHint()
            }
            if stability.frameCount >= required {
                triggerCapture(imageData: imageData)
            }
        case .countdown(let seconds):
            guard stability.countdownTask == nil else { return }
            showValidFrameHint()
            startCountdown(seconds: seconds)
        }
    }

    // Called by CameraViewController when Yoti delegate reports an analysis error
    func didFailCapture(reason: String) {
        guard captureStatus != .captured else { return }
        cancelStability()
        throttledHintUpdate(reason: reason)
    }

    // Called by CameraViewController when camera starts analyzing
    func didStartAnalyzing() {
        cancelStability()
        captureStatus = .analyzing
        hint = String(localized: "Align your face here", bundle: .module)
        isAnalysisError = false
        lastHintChangeDate = .distantPast
    }

    // Resets all state – triggers camera view to restart analysis via updateUIViewController
    public func reset() {
        cancelStability()
        captureStatus = .idle
        verificationStatus = .idle
        hint = String(localized: "Align your face here", bundle: .module)
        isAnalysisError = false
        isReadyForAnalysing = true
        capturedImageData = nil
        lastHintChangeDate = .distantPast
    }

    // MARK: - Private

    private func showValidFrameHint() {
        hint = String(localized: "Valid frame", bundle: .module)
        isAnalysisError = false
    }

    private func triggerCapture(imageData: Data) {
        captureStatus = .captured
        isReadyForAnalysing = false
        capturedImageData = imageData
        Task {
            await verify(imageData: imageData)
        }
    }

    private func startCountdown(seconds: Int) {
        countdown = seconds
        stability.countdownTask = Task {
            for remaining in stride(from: seconds - 1, through: 1, by: -1) {
                try? await Task.sleep(for: .seconds(1))
                guard !Task.isCancelled else { return }
                countdown = remaining
            }
            try? await Task.sleep(for: .seconds(1))
            guard !Task.isCancelled, let imageData = stability.latestImageData else { return }
            countdown = nil
            triggerCapture(imageData: imageData)
        }
    }

    private func cancelStability() {
        stability.reset()
        countdown = nil
    }

    // Shows the first new error immediately, then rate-limits further changes to once
    // per 300ms. Prevents visual flickering from rapid per-frame Yoti callbacks while
    // still reliably surfacing errors (unlike debounce, which waits for stability).
    private func throttledHintUpdate(reason: String) {
        guard hint != reason else { return }
        let now = Date.now
        guard now.timeIntervalSince(lastHintChangeDate) >= 0.3 else { return }
        hint = reason
        isAnalysisError = true
        lastHintChangeDate = now
    }

    private func verify(imageData: Data) async {
        verificationStatus = .uploading
        do {
            let result = try await verificationService.verify(imageData: imageData)
            verificationStatus = .verified(result)
        } catch {
            verificationStatus = .failed(error.localizedDescription)
        }
    }
}
