//
//  CameraViewController.swift
//  FaceCaptureKit
//
//  Copyright © 2026 Uwe Tilemann. All rights reserved.
//

import AVFoundation
import UIKit
import YotiFaceCapture
import SwiftUI

struct CameraView: UIViewControllerRepresentable {
    let model: FaceCaptureModel

    func makeUIViewController(context: Context) -> CameraViewController {
        CameraViewController(model: model)
    }

    func updateUIViewController(_ uiViewController: CameraViewController, context: Context) {
        switch model.captureStatus {
        case .idle:
            uiViewController.restartAnalysisIfNeeded()
        case .captured:
            uiViewController.stopFaceAnalysis()
        case .analyzing:
            break
        }
    }
}

final class CameraViewController: UIViewController {
    private let model: FaceCaptureModel

    private lazy var faceCaptureViewController: YotiFaceCapture.FaceCaptureViewController = {
        FaceCapture.uiConfiguration?.increaseScreenBrigthnessDuringCapture = true
        let faceCaptureViewController = FaceCapture.faceCaptureViewController()
        faceCaptureViewController.delegate = self
        faceCaptureViewController.view.translatesAutoresizingMaskIntoConstraints = false
        return faceCaptureViewController
    }()

    private let faceCenter = CGPoint(x: 0.5, y: 0.45)
    private var isCameraReady = false
    private var isAnalyzing = false

    init(model: FaceCaptureModel) {
        self.model = model
        super.init(nibName: nil, bundle: nil)
    }

    required init?(coder: NSCoder) {
        fatalError("init(coder:) has not been implemented")
    }

    override func viewDidLoad() {
        super.viewDidLoad()
        view.backgroundColor = .black
    }

    override func viewWillAppear(_ animated: Bool) {
        super.viewWillAppear(animated)
        addFaceCaptureViewController()
        requestCameraAccess()
    }

    override func viewWillDisappear(_ animated: Bool) {
        super.viewWillDisappear(animated)
        removeFaceCaptureViewController()
    }

    func restartAnalysisIfNeeded() {
        // isCameraReady prevents premature startAnalyzing calls before cameraReady fires
        guard isCameraReady, !isAnalyzing else { return }
        startFaceAnalysis()
    }
}

// MARK: - FaceCaptureViewDelegate

extension CameraViewController: FaceCaptureViewDelegate {
    func faceCaptureStateDidChange(to state: FaceCaptureState) {
        switch state {
        case .cameraReady:
            isCameraReady = true
            startFaceAnalysis()
        case .cameraStopped:
            isCameraReady = false
        case .analyzing:
            break
        @unknown default:
            return
        }
    }

    func faceCaptureStateFailed(withError error: FaceCaptureStateError) {
        switch error.code {
        case .cameraNotAccessible:
            print("Camera permissions not authorized")
        case .cameraInitializingError:
            if let underlyingError = error.underlyingError as NSError? {
                print("Camera initialization failed: \(underlyingError.localizedDescription)")
            }
        case .invalidState:
            print("Undefined error")
        @unknown default:
            return
        }
        showAlert(
            title: "Error",
            message: "An error occurred: \(error)",
            buttons: [.init(title: "OK", style: .cancel, handler: nil)]
        )
    }

    func faceCaptureDidAnalyzeImage(_ originalImage: UIImage?, withAnalysis analysis: FaceCaptureAnalysis) {
        let imageData = analysis.croppedImageData
        Task { @MainActor in
            model.didReceiveValidFrame(imageData: imageData)
        }
    }

    func faceCaptureDidAnalyzeImage(_ originalImage: UIImage?, withError error: FaceCaptureAnalysisError) {
        Task { @MainActor in
            // Blinking during an active countdown or frame-count sequence is normal
            // and should not reset the stability phase.
            if error == .eyesNotOpen, model.isStabilityInProgress { return }
            model.didFailCapture(reason: error.displayErrorMessage)
        }
    }
}

// MARK: - Helpers

private extension CameraViewController {
    func requestCameraAccess() {
        AVCaptureDevice.requestAccess(for: .video) { [weak self] granted in
            DispatchQueue.main.async {
                if granted {
                    self?.startCamera()
                } else {
                    self?.showCameraPermissionDeniedAlert()
                }
            }
        }
    }

    func startCamera() {
        faceCaptureViewController.startCamera()
    }

    func startFaceAnalysis() {
        guard !isAnalyzing else { return }
        guard model.isReadyForAnalysing else { return }

        isAnalyzing = true
        let configuration = Configuration(
            faceCenter: faceCenter,
            imageQuality: .default,
            validationOptions: [
                .eyesNotOpen,
                .environmentTooDark(threshold: .flexible),
            ]
        )
        faceCaptureViewController.startAnalyzing(withConfiguration: configuration)
        Task { @MainActor in
            model.didStartAnalyzing()
        }
    }

}

extension CameraViewController {
    func stopFaceAnalysis() {
        isAnalyzing = false
        faceCaptureViewController.stopAnalyzing()
    }
}

// MARK: - Add / Remove child FaceCaptureViewController

private extension CameraViewController {
    func addFaceCaptureViewController() {
        addChild(faceCaptureViewController)
        view.addSubview(faceCaptureViewController.view)
        faceCaptureViewController.view.frame = view.bounds
        faceCaptureViewController.view.autoresizingMask = [.flexibleWidth, .flexibleHeight]
        faceCaptureViewController.didMove(toParent: self)
    }

    func removeFaceCaptureViewController() {
        isCameraReady = false
        isAnalyzing = false
        faceCaptureViewController.willMove(toParent: nil)
        faceCaptureViewController.view.removeFromSuperview()
        faceCaptureViewController.removeFromParent()
    }
}

// MARK: - CameraPermissionDeniedDisplaying

extension CameraViewController: CameraPermissionDeniedDisplaying {}
