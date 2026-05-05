//
//  CameraOverlayView.swift
//  FaceCaptureKit
//
//  Copyright © 2026 Uwe Tilemann. All rights reserved.
//

import SwiftUI

struct CameraOverlayView: View {
    let model: FaceCaptureModel

    var body: some View {
        GeometryReader { geometry in
            ZStack {
                Image("cameraFaceFrame", bundle: .module)
                    .resizable()
                    .scaledToFill()
                    .frame(width: geometry.size.width, height: geometry.size.height)
                    .clipped()

                VStack(spacing: 0) {
                    // Position hint above the face oval (face center is at y: 0.45)
                    Color.clear
                        .frame(height: geometry.size.height * 0.26)

                    hintBadge

                    Spacer()
                }

                countdownOverlay
            }
            .animation(.easeInOut(duration: 0.35), value: model.countdown)
        }
        .ignoresSafeArea()
    }

    // MARK: - Countdown Overlay

    @ViewBuilder
    private var countdownOverlay: some View {
        if let count = model.countdown {
            Text("\(count)")
                .font(.system(size: 120, weight: .black, design: .rounded))
                .foregroundStyle(.white)
                .shadow(color: .black.opacity(0.45), radius: 16, x: 0, y: 4)
                .id(count)
                .transition(.asymmetric(
                    insertion: .scale(scale: 1.5).combined(with: .opacity),
                    removal: .scale(scale: 0.5).combined(with: .opacity)
                ))
        }
    }

    // MARK: - Hint Badge

    private var hintBadge: some View {
        ZStack {
            Text(model.hint)
                .font(.subheadline.weight(.semibold))
                .foregroundStyle(.white)
                .multilineTextAlignment(.center)
                .padding(.horizontal, 20)
                .padding(.vertical, 10)
                .background(hintColor, in: Capsule())
                // Unique ID forces SwiftUI to treat each new hint as a new view,
                // which triggers the transition animation on text changes
                .id(String(describing: model.hint))
                .transition(.opacity)
        }
        .animation(.easeInOut(duration: 0.25), value: String(describing: model.hint))
        .frame(maxWidth: .infinity)
    }

    private var hintColor: Color {
        switch model.captureStatus {
        case .captured:
            return .green.opacity(0.85)
        case .analyzing where model.isAnalysisError:
            return .orange.opacity(0.85)
        default:
            return .black.opacity(0.55)
        }
    }
}

// MARK: - Captured Face Preview
struct CapturedPreview: View {
    let model: FaceCaptureModel

    var body: some View {
        if let data = model.capturedImageData,
           let image = UIImage(data: data) {
            Image(uiImage: image)
                .resizable()
                .scaledToFit()
                .clipShape(RoundedRectangle(cornerRadius: 8))
                .overlay(
                    RoundedRectangle(cornerRadius: 8)
                        .stroke(.white.opacity(0.5), lineWidth: 1)
                )
        }
    }
}
