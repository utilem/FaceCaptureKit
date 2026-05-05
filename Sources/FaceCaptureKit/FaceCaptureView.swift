//
//  FaceCaptureView.swift
//  FaceCaptureKit
//
//  Copyright © 2026 Uwe Tilemann. All rights reserved.
//

import SwiftUI

/// The main entry point for face capture and age verification.
/// Drop this view into your app's hierarchy and provide a verification service.
public struct FaceCaptureView: View {
    @Environment(\.scenePhase) private var scenePhase
    @State private var model: FaceCaptureModel

    public init(model: FaceCaptureModel) {
        _model = State(wrappedValue: model)
    }

    public var body: some View {
        ZStack {
            if scenePhase == .active {
                CameraView(model: model)
                    .ignoresSafeArea()
            }

            CameraOverlayView(model: model)

            uploadingOverlay
        }
        .onChange(of: scenePhase) { _ in
            if scenePhase == .active {
                model.reset()
            }
        }
        .sheet(isPresented: isShowingResult) {
            VStack(spacing: 24) {
                ZStack(alignment: .bottomTrailing) {
                    CapturedPreview(model: model)
                    VerificationResultIcon(verificationStatus: model.verificationStatus)
                }
                VerificationResultLabel(verificationStatus: model.verificationStatus)
                Button(String(localized: "Try Again", bundle: .module), action: { model.reset() })
                    .buttonStyle(.borderedProminent)
            }
            .padding()
            .frame(maxWidth: .infinity, maxHeight: .infinity)
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

    private var isShowingResult: Binding<Bool> {
        Binding(
            get: { model.verificationStatus.isTerminal },
            set: { if !$0 { model.reset() } }
        )
    }
}
