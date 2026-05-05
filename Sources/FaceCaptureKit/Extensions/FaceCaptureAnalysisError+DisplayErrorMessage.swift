//
//  FaceCaptureAnalysisError+DisplayErrorMessage.swift
//  FaceCaptureKit
//
//  Copyright © 2026 Uwe Tilemann. All rights reserved.
//

import SwiftUI
import YotiFaceCapture

extension FaceCaptureAnalysisError {
    var displayErrorMessage: String {
        switch self {
        case .noFaceDetected:
            return String(localized: "No face detected", bundle: .module)
        case .multipleFaces:
            return String(localized: "Multiple faces", bundle: .module)
        case .faceTooSmall:
            return String(localized: "Face too small", bundle: .module)
        case .faceTooBig:
            return String(localized: "Face too big", bundle: .module)
        case .faceNotCentered:
            return String(localized: "Face not centered", bundle: .module)
        case .faceAnalysisFailed:
            return String(localized: "Face analysis failed", bundle: .module)
        case .eyesNotOpen:
            return String(localized: "Eyes not open", bundle: .module)
        case .faceNotStable:
            return String(localized: "Face not stable", bundle: .module)
        case .faceNotStraight:
            return String(localized: "Face not straight", bundle: .module)
        case .environmentTooDark:
            return String(localized: "Environment too dark", bundle: .module)
        @unknown default:
            return String(localized: "Invalid Result", bundle: .module)
        }
    }
}
