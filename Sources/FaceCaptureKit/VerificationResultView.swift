//
//  VerificationResultView.swift
//  FaceCaptureKit
//
//  Copyright © 2026 Uwe Tilemann. All rights reserved.
//

import SwiftUI

struct VerificationResultIcon: View {
    let verificationStatus: VerificationStatus

    var body: some View {
        switch verificationStatus {
        case .verified(let result):
            Image(systemName: result.isVerified ? "checkmark.seal.fill" : "xmark.seal.fill")
                .font(.system(size: 64))
                .foregroundStyle(result.isVerified ? .green : .orange)
        case .failed:
            Image(systemName: "exclamationmark.triangle.fill")
                .font(.system(size: 64))
                .foregroundStyle(.red)
        default:
            EmptyView()
        }
    }
}

struct VerificationResultLabel: View {
    let verificationStatus: VerificationStatus
    
    var body: some View {
        switch verificationStatus {
        case .verified(let result):
            VStack(spacing: 8) {
                Text(verificationStatus.statusString)
                    .font(.title2.bold())
                if let age = result.estimatedAge {
                    Text(String(format: String(localized: "Estimated age: %lld", bundle: .module), age))
                        .foregroundStyle(.secondary)
                }
                if let message = result.message {
                    Text(message)
                        .font(.caption)
                        .foregroundStyle(.secondary)
                        .multilineTextAlignment(.center)
                }
            }
        case .failed(let errorMessage):
            VStack(spacing: 8) {
                Text(verificationStatus.statusString)
                    .font(.title2.bold())
                Text(errorMessage)
                    .font(.subheadline)
                    .foregroundStyle(.secondary)
                    .multilineTextAlignment(.center)
            }
        default:
            EmptyView()
        }
    }
}

struct VerificationResultView: View {
    let verificationStatus: VerificationStatus
    let onRetry: () -> Void

    var body: some View {
        VStack(spacing: 24) {
            VerificationResultIcon(verificationStatus: verificationStatus)
            VerificationResultLabel(verificationStatus: verificationStatus)
            
            Button(String(localized: "Try Again", bundle: .module), action: onRetry)
                .buttonStyle(.borderedProminent)
        }
        .padding(32)
        .frame(maxWidth: .infinity, maxHeight: .infinity)
    }
}
