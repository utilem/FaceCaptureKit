//
//  UIViewController+AlertExtension.swift
//  FaceCaptureKit
//
//  Copyright © 2026 Uwe Tilemann. All rights reserved.
//

import UIKit

extension UIViewController {
    func showAlert(
        title: String,
        message: String,
        buttons: [UIAlertAction]
    ) {
        let alertVC = UIAlertController(
            title: title,
            message: message,
            preferredStyle: .alert
        )
        for button in buttons {
            alertVC.addAction(button)
        }
        present(
            alertVC,
            animated: true,
            completion: nil
        )
    }
}
