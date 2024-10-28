//
//  Passcode.swift
//  PasscodeKit
//
//  Created by Dominic Rodemer on 22.10.24.
//

import UIKit
import LocalAuthentication

import CryptoKit
import KeychainKit

@objc protocol PasscodeDelegate {

    @objc optional func passcodeCreated(_ passcode: Passcode)
    @objc optional func passcodeChanged(_ passcode: Passcode)
    @objc optional func passcodeRemoved(_ passcode: Passcode)

    @objc optional func passcodeAuthenticated(_ passcode: Passcode)
    @objc optional func passcodeAuthenticationFaliure(_ passcode: Passcode)
}

@objc public class Passcode : NSObject {
    
    @objc public static let PasscodeCreatedNotification = NSNotification.Name("PKPasscodeCreatedNotification")
    @objc public static let PasscodeChangedNotification = NSNotification.Name("PKPasscodeChangedNotification")
    @objc public static let PasscodeRemovedNotification = NSNotification.Name("PKPasscodeRemovedNotification")
    @objc public static let PasscodeAuthenticatedNotification = NSNotification.Name("PKPasscodeAuthenticatedNotification")
    @objc public static let PasscodeAuthenticationFaliureNotification = NSNotification.Name("PKPasscodeAuthenticationFaliureNotification")
    
    let key: String
    private let keychainKey: String
        
    var delegate: PasscodeDelegate?
    
    @objc public init(key: String) {
        self.key = key
        self.keychainKey = "net.domzilla.PasscodeKit." + self.key
        
        super.init()
    }
    
    @objc public func lock(_ viewController: UIViewController) {
        if self.isPasscodeSet() {
            let authenticateViewController = AuthenticateViewController(passcode: self)
            viewController.addChild(authenticateViewController)
            viewController.view.addSubview(authenticateViewController.view)
            authenticateViewController.didMove(toParent: viewController)
        }
    }
    
    @objc public func create(presentOn viewController: UIViewController, animated: Bool) {
        let createPasscodeViewController = CreatePasscodeViewController(passcode: self)
        let navigationController = UINavigationController(rootViewController: createPasscodeViewController)
        viewController.present(navigationController, animated: animated)
    }

    @objc public func remove(presentOn viewController: UIViewController, animated: Bool) {
        if self.isPasscodeSet() {
            let removePasscodeViewController = RemovePasscodeViewController(passcode: self)
            let navigationController = UINavigationController(rootViewController: removePasscodeViewController)
            viewController.present(navigationController, animated: animated)
        }
    }
    
    @objc public func change(presentOn viewController: UIViewController, animated: Bool) {
        if self.isPasscodeSet() {
            let changePasscodeViewController = ChangePasscodeViewController(passcode: self)
            let navigationController = UINavigationController(rootViewController: changePasscodeViewController)
            viewController.present(navigationController, animated: animated)
        }
    }
    
    @objc public func isPasscodeSet() -> Bool {
        return Keychain.default.string(forKey: self.keychainKey) != nil
    }
    
    @objc public static func canEnableBiometrics() -> Bool {
        let context = LAContext()
        var error: NSError?
        let canEnableBiometrics = context.canEvaluatePolicy(.deviceOwnerAuthenticationWithBiometrics, error: &error)
        if let error = error {debugPrint(error)}
        
        return canEnableBiometrics
    }
    
    @objc public static func enableBiometrics(_ enable: Bool) async throws -> Bool {
        if enable {
            if self.canEnableBiometrics() {
                let context = LAContext()
                #warning("TODO localizedReason")
                let enabled = try await context.evaluatePolicy(.deviceOwnerAuthenticationWithBiometrics, localizedReason: "LOL")
                UserDefaults.standard.setValue(enabled, forKey: "net.domzilla.PasscodeKit.enableBiometrics")
                UserDefaults.standard.synchronize()
                return enabled
            }
        } else {
            UserDefaults.standard.setValue(false, forKey: "net.domzilla.PasscodeKit.enableBiometrics")
            UserDefaults.standard.synchronize()
        }
        
        return false
    }
    
    @objc public static func isBiometricsEnabled() -> Bool {
        return UserDefaults.standard.bool(forKey: "net.domzilla.PasscodeKit.enableBiometrics")
    }
    
    internal func create(_ code: String) {
        let sha256 = self.sha256(code)
        Keychain.default.set(sha256, forKey: self.keychainKey)
        DispatchQueue.main.async {
            self.delegate?.passcodeCreated?(self)
            NotificationCenter.default.post(name: Passcode.PasscodeCreatedNotification, object: self)
        }
    }
    
    internal func change(_ code: String) {
        if self.isPasscodeSet() {
            let sha256 = self.sha256(code)
            Keychain.default.set(sha256, forKey: self.keychainKey)
            DispatchQueue.main.async {
                self.delegate?.passcodeChanged?(self)
                NotificationCenter.default.post(name: Passcode.PasscodeChangedNotification, object: self)
            }
        }
    }
    
    internal func remove() {
        if self.isPasscodeSet() {
            Keychain.default.removeObject(forKey: self.keychainKey)
            DispatchQueue.main.async {
                self.delegate?.passcodeRemoved?(self)
                NotificationCenter.default.post(name: Passcode.PasscodeRemovedNotification, object: self)
            }
        }
    }

    internal func authenticate(_ code: String?) async throws -> Bool {
        var authenticated = false
        
        if let code = code {
            if let storedSha256 = Keychain.default.string(forKey: self.keychainKey) {
                let sha256 = self.sha256(code)
                authenticated = (sha256 == storedSha256)
            }
        } else if Passcode.isBiometricsEnabled() {
            let context = LAContext()
            var error: NSError?
            let biometricsAvailable = context.canEvaluatePolicy(.deviceOwnerAuthenticationWithBiometrics, error: &error)
            if let error = error {debugPrint(error)}
            
            if biometricsAvailable {
                #warning("TODO localizedReason")
                authenticated = try await context.evaluatePolicy(.deviceOwnerAuthenticationWithBiometrics, localizedReason: "LOL")
            }
        }
        
        if authenticated {
            DispatchQueue.main.async {
                self.delegate?.passcodeAuthenticated?(self)
                NotificationCenter.default.post(name: Passcode.PasscodeAuthenticatedNotification, object: self)
            }
        } else {
            DispatchQueue.main.async {
                self.delegate?.passcodeAuthenticationFaliure?(self)
                NotificationCenter.default.post(name: Passcode.PasscodeAuthenticationFaliureNotification, object: self)
            }
        }
        
        return authenticated
    }
}

private extension Passcode {
    
    func sha256(_ string: String) -> String {
        let data = Data(string.utf8)
        let hash = SHA256.hash(data: data)
        return hash.compactMap {String(format: "%02x", $0)}.joined()
    }
}
