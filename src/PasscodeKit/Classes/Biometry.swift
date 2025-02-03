//
//  Biometry.swift
//  PasscodeKit
//
//  Created by Dominic Rodemer on 04.11.24.
//

import UIKit

import LocalAuthentication

@objc public class Biometry: NSObject {
    
    @objc public static let shared = Biometry()
    
    @objc public var type: LABiometryType = .none
    @objc public var name: String?
    @objc public var imageName: String?
    
    override init() {
        super.init()
        
        let context = LAContext()
        var error: NSError?
        _ = context.canEvaluatePolicy(.deviceOwnerAuthenticationWithBiometrics, error: &error)
        if let error = error {debugPrint(error)}
        
        self.type = context.biometryType
        
        if #available(iOS 17.0, *) {
            if self.type == .opticID {
                self.name = "Optic ID"
                self.imageName = "opticid"
            }
        }
        
        if self.type == .faceID {
            self.name = "Face ID"
            self.imageName = "faceid"
        } else if self.type == .touchID {
            self.name = "Touch ID"
            self.imageName = "touchid"
        }
    }
    
    @objc public static func presentErrorAlert(on viewController: UIViewController, with error: Error, appName: String) {
        if let error = error as? LAError {
            if error.code == .biometryNotAvailable {
                let alertController = UIAlertController(title: error.localizedDescription,
                                                        message: String(format: NSLocalizedString("%@ doesn't have access to biometric authentication.",
                                                                                                  bundle: Bundle.PasscodeKitRessourceBundle,
                                                                                                  comment: "Message that the app doesn't have access rights to biometric authentication. Placeholder is app name."), appName),
                                                        preferredStyle: .alert)
                alertController.addAction(UIAlertAction(title: NSLocalizedString("Cancel", 
                                                                                 bundle: Bundle.PasscodeKitRessourceBundle,
                                                                                 comment: "Title for 'Cancel' Button"), 
                                                        style: .cancel))
                alertController.addAction(UIAlertAction(title: NSLocalizedString("Settings",
                                                                                 bundle: Bundle.PasscodeKitRessourceBundle,
                                                                                 comment: "Title for 'Settings' Button"), 
                                                        style: .default,
                                                        handler: { action in
                    UIApplication.shared.open(URL(string: UIApplication.openSettingsURLString)!, options: [:], completionHandler: nil)
                }))
                viewController.present(alertController, animated: true)
            }
        }
    }
}
