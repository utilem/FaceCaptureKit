//
//  FaceCaptureView.swift
//  FaceCaptureKit
//
//  Copyright © 2026 Uwe Tilemann. All rights reserved.
//

import SwiftUI

/// The main entry point for face capture and age verification.
/// Drop this view into your app's hierarchy and provide a verification service.
///
/// By default a sheet with ``VerificationResultView`` is presented when verification completes.
/// Pass a `result` closure to replace that sheet with any view you choose — or to react to
/// the result in a completely different way (e.g. push to a new screen, show a full-screen overlay).
///
/// ```swift
/// // Default – built-in result sheet
/// FaceCaptureView(model: model)
///
/// // Custom – your own UI, shown as a full-screen overlay over the camera
/// FaceCaptureView(model: model) { status, retry in
///     MyResultView(status: status, onRetry: retry)
/// }
/// ```
public struct FaceCaptureView: View {
    @Environment(\.scenePhase) private var scenePhase
    @State private var model: FaceCaptureModel

    // Non-nil when the caller supplied a custom result view.
    private let resultContent: ((VerificationStatus, @escaping () -> Void) -> AnyView)?

    /// Creates a view that presents the built-in result sheet on completion.
    public init(model: FaceCaptureModel) {
        _model = State(wrappedValue: model)
        resultContent = nil
    }

    /// Creates a view that calls `result` when verification completes and shows the
    /// returned view as a full-screen overlay over the camera.
    ///
    /// - Parameters:
    ///   - model: The shared ``FaceCaptureModel``.
    ///   - result: A `@ViewBuilder` closure receiving the terminal ``VerificationStatus``
    ///     and a `retry` closure that resets the model. Return any `View` you like.
    public init<Content: View>(
        model: FaceCaptureModel,
        @ViewBuilder result: @escaping (VerificationStatus, @escaping () -> Void) -> Content
    ) {
        _model = State(wrappedValue: model)
        resultContent = { status, retry in AnyView(result(status, retry)) }
    }

    public var body: some View {
        ZStack {
            if scenePhase == .active {
                CameraView(model: model)
                    .ignoresSafeArea()
            }

            CameraOverlayView(model: model)

            uploadingOverlay

            if let resultContent, model.verificationStatus.isTerminal {
                resultContent(model.verificationStatus, { model.reset() })
                    .transition(.opacity)
                    .zIndex(1)
            }
        }
        .animation(.easeInOut(duration: 0.25), value: model.verificationStatus.isTerminal)
        .onChange(of: scenePhase) { _ in
            if scenePhase == .active {
                model.reset()
            }
        }
        // Only active when no custom result handler is provided.
        .sheet(isPresented: defaultSheetBinding) {
            VerificationResultView(
                verificationStatus: model.verificationStatus,
                onRetry: { model.reset() }
            )
            .presentationDetents([.medium])
        }
    }

    @ViewBuilder
    private var uploadingOverlay: some View {
        if case .uploading = model.verificationStatus {
            VStack(spacing: 12) {
                ProgressView()
                Text(String(localized: "Verifying age…", bundle: .module))
                    .font(.subheadline)
            }
            .padding(24)
            .background(.regularMaterial)
            .clipShape(RoundedRectangle(cornerRadius: 16))
        }
    }

    private var defaultSheetBinding: Binding<Bool> {
        Binding(
            get: { resultContent == nil && model.verificationStatus.isTerminal },
            set: { if !$0 { model.reset() } }
        )
    }
}
