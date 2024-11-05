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
        let canEnableBiometrics = context.canEvaluatePolicy(.deviceOwnerAuthenticationWithBiometrics, error: &error)
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
}
