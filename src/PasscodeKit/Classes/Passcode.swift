//
//  Passcode.swift
//  PasscodeKit
//
//  Created by Dominic Rodemer on 22.10.24.
//

import UIKit
import LocalAuthentication

import CryptoKit

@objc protocol PasscodeDelegate {

    @objc optional func passcodeCreated(_ passcode: Passcode)
    @objc optional func passcodeChanged(_ passcode: Passcode)
    @objc optional func passcodeRemoved(_ passcode: Passcode)

    @objc optional func passcodeAuthenticated(_ passcode: Passcode)
    @objc optional func passcodeAuthenticationFaliure(_ passcode: Passcode)
}

internal enum PasscodeOption: String {
    case fourDigits
    case sixDigits
    case alphanumerical
    
    init(rawValue: String?) {
        switch rawValue {
        case PasscodeOption.fourDigits.rawValue:
            self = .fourDigits
        case PasscodeOption.sixDigits.rawValue:
            self = .sixDigits
        default:
            self = .alphanumerical
        }
    }
    
    var length: Int {
        switch self {
        case .fourDigits:
            return 4
        case .sixDigits:
            return 6
        default:
            return Int.max
        }
    }
}

@objc public class Passcode : NSObject {
    
    @objc public static let PasscodeCreatedNotification = NSNotification.Name("PKPasscodeCreatedNotification")
    @objc public static let PasscodeChangedNotification = NSNotification.Name("PKPasscodeChangedNotification")
    @objc public static let PasscodeRemovedNotification = NSNotification.Name("PKPasscodeRemovedNotification")
    @objc public static let PasscodeAuthenticatedNotification = NSNotification.Name("PKPasscodeAuthenticatedNotification")
    @objc public static let PasscodeAuthenticationFaliureNotification = NSNotification.Name("PKPasscodeAuthenticationFaliureNotification")
    
    let key: String
    private let userDefaultsKey: String
    private let sha256Key = "sha256"
    private let optionKey = "option"
    
    internal var option: PasscodeOption {
        if let dict = UserDefaults.standard.object(forKey: self.userDefaultsKey) as? [String: String] {
            return PasscodeOption(rawValue: dict[self.optionKey])
        }
        
        return .fourDigits
    }
            
    var delegate: PasscodeDelegate?
    
    @objc public init(key: String) {
        self.key = key
        self.userDefaultsKey = "net.domzilla.PasscodeKit." + self.key
        
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
    
    @objc public func create(_ code: String) {
        let dict = [self.sha256Key: self.sha256(code),
                    self.optionKey: self.option(for: code).rawValue]
        UserDefaults.standard.setValue(dict, forKey: self.userDefaultsKey)
        DispatchQueue.main.async {
            self.delegate?.passcodeCreated?(self)
            NotificationCenter.default.post(name: Passcode.PasscodeCreatedNotification, object: self)
        }
    }

    @objc public func remove(presentOn viewController: UIViewController, animated: Bool) {
        if self.isPasscodeSet() {
            let removePasscodeViewController = RemovePasscodeViewController(passcode: self)
            let navigationController = UINavigationController(rootViewController: removePasscodeViewController)
            viewController.present(navigationController, animated: animated)
        }
    }
    
    @objc public func remove() {
        if self.isPasscodeSet() {
            UserDefaults.standard.removeObject(forKey: self.userDefaultsKey)
            DispatchQueue.main.async {
                self.delegate?.passcodeRemoved?(self)
                NotificationCenter.default.post(name: Passcode.PasscodeRemovedNotification, object: self)
            }
        }
    }
    
    @objc public func change(presentOn viewController: UIViewController, animated: Bool) {
        if self.isPasscodeSet() {
            let changePasscodeViewController = ChangePasscodeViewController(passcode: self)
            let navigationController = UINavigationController(rootViewController: changePasscodeViewController)
            viewController.present(navigationController, animated: animated)
        }
    }
    
    @objc public func change(_ code: String) {
        if self.isPasscodeSet() {
            let dict = [self.sha256Key: self.sha256(code),
                        self.optionKey: self.option(for: code).rawValue]
            UserDefaults.standard.setValue(dict, forKey: self.userDefaultsKey)
            DispatchQueue.main.async {
                self.delegate?.passcodeChanged?(self)
                NotificationCenter.default.post(name: Passcode.PasscodeChangedNotification, object: self)
            }
        }
    }
    
    @objc public func authenticate(_ code: String?) async throws -> Bool {
        var authenticated = false
        
        if let code = code {
            if let dict = UserDefaults.standard.object(forKey: self.userDefaultsKey) as? [String: String] {
                let storedSha256 = dict[self.sha256Key];
                let sha256 = self.sha256(code)
                authenticated = (sha256 == storedSha256)
            }
        } else if Passcode.isBiometricsEnabled() {
            let context = LAContext()
            var error: NSError?
            let biometricsAvailable = context.canEvaluatePolicy(.deviceOwnerAuthenticationWithBiometrics, error: &error)
            if let error = error {throw error}
            
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
    
    @objc public func isPasscodeSet() -> Bool {
        return UserDefaults.standard.object(forKey: self.userDefaultsKey) != nil
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
            let context = LAContext()
            var error: NSError?
            let canEnableBiometrics = context.canEvaluatePolicy(.deviceOwnerAuthenticationWithBiometrics, error: &error)
            if let error = error {throw error}
            
            if canEnableBiometrics {
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
}


private extension Passcode {
    
    func sha256(_ string: String) -> String {
        let data = Data(string.utf8)
        let hash = SHA256.hash(data: data)
        return hash.compactMap {String(format: "%02x", $0)}.joined()
    }
    
    func option(for code: String) -> PasscodeOption {
        
        let digitCharacters = CharacterSet(charactersIn: "0123456789")
        let isNumeric = CharacterSet(charactersIn: code).isSubset(of: digitCharacters)
        
        if isNumeric {
            if code.count == 4 {
                return .fourDigits
            }
            if code.count == 6 {
                return .sixDigits
            }
        }
        
        return .alphanumerical
    }
}
