//
//  Passcode.swift
//  PasscodeKit
//
//  Created by Dominic Rodemer on 22.10.24.
//

import CryptoKit
import LocalAuthentication
import UIKit

@objc
protocol PasscodeDelegate {
    @objc
    optional func passcodeCreated(_ passcode: Passcode)

    @objc
    optional func passcodeChanged(_ passcode: Passcode)

    @objc
    optional func passcodeRemoved(_ passcode: Passcode)

    @objc
    optional func passcodeAuthenticated(_ passcode: Passcode)

    @objc
    optional func passcodeAuthenticationFaliure(_ passcode: Passcode)
}

enum PasscodeOption: String {
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
            4
        case .sixDigits:
            6
        default:
            Int.max
        }
    }
}

/// A closure invoked with the result of a passcode authentication attempt.
///
/// The closure receives `true` if the user successfully authenticated, or `false` if
/// the user cancelled the authentication flow. Failed attempts do not invoke the closure.
public typealias AuthenticationHandler = (Bool) -> Void

/// Manages the creation, storage, authentication, and removal of an in-app passcode.
///
/// Each `Passcode` instance is identified by a unique key and stores its hashed passcode
/// value in `UserDefaults` under the `net.domzilla.PasscodeKit.*` namespace. The class
/// supports both code-based and UI-based workflows for creating, changing, removing, and
/// authenticating passcodes. It also provides static methods for managing device biometric
/// authentication (Face ID, Touch ID, Optic ID).
///
/// - Note: Passcode hashing uses SHA256 by default. Set ``legacyMD5Support`` to `true`
///   to use MD5 instead for backwards compatibility with older stored hashes.
@objc
public class Passcode: NSObject {
    /// Posted on the main thread after a new passcode has been created and stored.
    ///
    /// The notification `object` is the `Passcode` instance that was created.
    @objc public static let PasscodeCreatedNotification = NSNotification.Name("PKPasscodeCreatedNotification")

    /// Posted on the main thread after an existing passcode has been changed.
    ///
    /// The notification `object` is the `Passcode` instance whose passcode was changed.
    @objc public static let PasscodeChangedNotification = NSNotification.Name("PKPasscodeChangedNotification")

    /// Posted on the main thread after a passcode has been removed from storage.
    ///
    /// The notification `object` is the `Passcode` instance whose passcode was removed.
    @objc public static let PasscodeRemovedNotification = NSNotification.Name("PKPasscodeRemovedNotification")

    /// Posted on the main thread after a successful authentication against the stored passcode or via biometrics.
    ///
    /// The notification `object` is the `Passcode` instance that was authenticated.
    @objc public static let PasscodeAuthenticatedNotification = NSNotification
        .Name("PKPasscodeAuthenticatedNotification")

    /// Posted on the main thread after a failed authentication attempt.
    ///
    /// The notification `object` is the `Passcode` instance where authentication failed.
    @objc public static let PasscodeAuthenticationFaliureNotification = NSNotification
        .Name("PKPasscodeAuthenticationFaliureNotification")

    /// Enables legacy MD5 hashing instead of the default SHA256.
    ///
    /// Set this to `true` before any passcode operations if the app previously
    /// stored passcode hashes using MD5 and needs backwards compatibility.
    /// Defaults to `false`.
    @objc public static var legacyMD5Support: Bool = false

    let key: String

    private let userDefaultsKey: String

    private static let hashKey = "hash"

    private static let optionKey = "option"

    var option: PasscodeOption {
        if let dict = UserDefaults.standard.object(forKey: self.userDefaultsKey) as? [String: String] {
            return PasscodeOption(rawValue: dict[Passcode.optionKey])
        }

        return .fourDigits
    }

    var delegate: PasscodeDelegate?

    /// Creates a new `Passcode` instance with the specified storage key.
    ///
    /// The key is used to construct a unique `UserDefaults` key under the
    /// `net.domzilla.PasscodeKit.*` namespace for persisting the passcode hash.
    ///
    /// - Parameter key: A unique string identifier for this passcode.
    @objc
    public init(key: String) {
        self.key = key
        self.userDefaultsKey = Passcode.userDefaultsKey(self.key)

        super.init()
    }

    /// Overlays a lock screen on the specified view controller if a passcode is set.
    ///
    /// Adds a `LockViewController` as a child of the given view controller, covering
    /// its entire view. The lock screen is removed automatically when the user
    /// successfully authenticates. Does nothing if no passcode has been set.
    ///
    /// - Parameter viewController: The view controller to overlay with the lock screen.
    @objc
    public func lock(_ viewController: UIViewController) {
        if self.isPasscodeSet() {
            let lockViewController = LockViewController(passcode: self)
            viewController.addChild(lockViewController)
            viewController.view.addSubview(lockViewController.view)
            lockViewController.didMove(toParent: viewController)
        }
    }

    /// Presents a modal authentication view controller that prompts the user to enter their passcode.
    ///
    /// The authentication view supports both passcode entry and biometric authentication
    /// (if enabled). The user can also cancel the authentication. The result is delivered
    /// through the provided handler closure. Does nothing if no passcode has been set.
    ///
    /// - Parameter viewController: The view controller to present the authentication UI on.
    /// - Parameter animated: Whether to animate the presentation.
    /// - Parameter handler: A closure called with `true` on successful authentication or `false` on cancellation.
    @objc
    public func authenticate(
        presentOn viewController: UIViewController,
        animated: Bool,
        handler: @escaping AuthenticationHandler
    ) {
        if self.isPasscodeSet() {
            let authenticateViewController = AuthenticateViewController(passcode: self, authenticationHandler: handler)
            let navigationController = UINavigationController(rootViewController: authenticateViewController)
            viewController.present(navigationController, animated: animated)
        }
    }

    /// Presents a modal view controller that guides the user through creating a new passcode.
    ///
    /// The user is prompted to enter and then verify a passcode. The passcode option
    /// (four-digit, six-digit, or alphanumeric) can be selected during creation. On
    /// successful creation, the passcode hash is stored and ``PasscodeCreatedNotification``
    /// is posted.
    ///
    /// - Parameter viewController: The view controller to present the creation UI on.
    /// - Parameter animated: Whether to animate the presentation.
    @objc
    public func create(presentOn viewController: UIViewController, animated: Bool) {
        let createPasscodeViewController = CreatePasscodeViewController(passcode: self)
        let navigationController = UINavigationController(rootViewController: createPasscodeViewController)
        viewController.present(navigationController, animated: animated)
    }

    /// Programmatically creates a passcode from the given plaintext code.
    ///
    /// Hashes the code, determines the appropriate ``PasscodeOption`` based on its
    /// format and length, and stores both the hash and option in `UserDefaults`.
    /// Notifies the delegate via ``PasscodeDelegate/passcodeCreated(_:)`` and posts
    /// ``PasscodeCreatedNotification`` on the main thread.
    ///
    /// - Parameter code: The plaintext passcode string to hash and store.
    @objc
    public func create(_ code: String) {
        let dict = [
            Passcode.hashKey: self.hash(code),
            Passcode.optionKey: self.option(for: code).rawValue,
        ]
        UserDefaults.standard.setValue(dict, forKey: self.userDefaultsKey)
        UserDefaults.standard.synchronize()
        DispatchQueue.main.async {
            self.delegate?.passcodeCreated?(self)
            NotificationCenter.default.post(name: Passcode.PasscodeCreatedNotification, object: self)
        }
    }

    /// Presents a modal view controller that prompts the user to authenticate before removing the passcode.
    ///
    /// The user must enter their current passcode to confirm removal. On successful
    /// authentication, the stored passcode is deleted and ``PasscodeRemovedNotification``
    /// is posted. Does nothing if no passcode has been set.
    ///
    /// - Parameter viewController: The view controller to present the removal UI on.
    /// - Parameter animated: Whether to animate the presentation.
    @objc
    public func remove(presentOn viewController: UIViewController, animated: Bool) {
        if self.isPasscodeSet() {
            let removePasscodeViewController = RemovePasscodeViewController(passcode: self)
            let navigationController = UINavigationController(rootViewController: removePasscodeViewController)
            viewController.present(navigationController, animated: animated)
        }
    }

    /// Programmatically removes the stored passcode.
    ///
    /// Deletes the passcode hash and option from `UserDefaults`. Notifies the delegate
    /// via ``PasscodeDelegate/passcodeRemoved(_:)`` and posts ``PasscodeRemovedNotification``
    /// on the main thread. Does nothing if no passcode has been set.
    @objc
    public func remove() {
        if self.isPasscodeSet() {
            UserDefaults.standard.removeObject(forKey: self.userDefaultsKey)
            UserDefaults.standard.synchronize()
            DispatchQueue.main.async {
                self.delegate?.passcodeRemoved?(self)
                NotificationCenter.default.post(name: Passcode.PasscodeRemovedNotification, object: self)
            }
        }
    }

    /// Presents a modal view controller that guides the user through changing their passcode.
    ///
    /// The user is first prompted to enter their current passcode for verification,
    /// then to enter and confirm a new passcode. On success, the new hash is stored and
    /// ``PasscodeChangedNotification`` is posted. Does nothing if no passcode has been set.
    ///
    /// - Parameter viewController: The view controller to present the change UI on.
    /// - Parameter animated: Whether to animate the presentation.
    @objc
    public func change(presentOn viewController: UIViewController, animated: Bool) {
        if self.isPasscodeSet() {
            let changePasscodeViewController = ChangePasscodeViewController(passcode: self)
            let navigationController = UINavigationController(rootViewController: changePasscodeViewController)
            viewController.present(navigationController, animated: animated)
        }
    }

    /// Programmatically changes the stored passcode to the given plaintext code.
    ///
    /// Hashes the new code, determines the appropriate ``PasscodeOption``, and updates
    /// the stored values in `UserDefaults`. Notifies the delegate via
    /// ``PasscodeDelegate/passcodeChanged(_:)`` and posts ``PasscodeChangedNotification``
    /// on the main thread. Does nothing if no passcode has been set.
    ///
    /// - Parameter code: The new plaintext passcode string to hash and store.
    @objc
    public func change(_ code: String) {
        if self.isPasscodeSet() {
            let dict = [
                Passcode.hashKey: self.hash(code),
                Passcode.optionKey: self.option(for: code).rawValue,
            ]
            UserDefaults.standard.setValue(dict, forKey: self.userDefaultsKey)
            UserDefaults.standard.synchronize()
            DispatchQueue.main.async {
                self.delegate?.passcodeChanged?(self)
                NotificationCenter.default.post(name: Passcode.PasscodeChangedNotification, object: self)
            }
        }
    }

    /// Authenticates against the stored passcode using either a plaintext code or biometrics.
    ///
    /// When `code` is non-nil, the method hashes it and compares it against the stored
    /// hash. When `code` is `nil` and biometrics are enabled, the method triggers a
    /// biometric authentication prompt via `LAContext`. On success, the delegate is
    /// notified via ``PasscodeDelegate/passcodeAuthenticated(_:)`` and
    /// ``PasscodeAuthenticatedNotification`` is posted. On failure, the delegate receives
    /// ``PasscodeDelegate/passcodeAuthenticationFaliure(_:)`` and
    /// ``PasscodeAuthenticationFaliureNotification`` is posted.
    ///
    /// - Parameter code: The plaintext passcode to verify, or `nil` to attempt biometric authentication.
    /// - Returns: `true` if the authentication succeeded, `false` otherwise.
    /// - Throws: An error from `LAContext` if biometrics are unavailable or evaluation fails
    ///   (including user cancellation). No failure notification is posted in that case.
    @objc
    public func authenticate(_ code: String?) async throws -> Bool {
        var authenticated = false

        if let code {
            if let dict = UserDefaults.standard.object(forKey: self.userDefaultsKey) as? [String: String] {
                let storedHash = dict[Passcode.hashKey]
                let hash = self.hash(code)
                authenticated = (hash == storedHash)
            }
        } else if Passcode.isBiometricsEnabled() {
            let context = LAContext()
            var error: NSError?
            let biometricsAvailable = context.canEvaluatePolicy(.deviceOwnerAuthenticationWithBiometrics, error: &error)
            if let error {
                throw error
            }

            if biometricsAvailable {
                authenticated = try await context.evaluatePolicy(
                    .deviceOwnerAuthenticationWithBiometrics,
                    localizedReason: NSLocalizedString(
                        "Verify your identity",
                        bundle: Bundle.PasscodeKitRessourceBundle,
                        comment: "Biometric authentication prompt reason"
                    )
                )
            }
        }

        if authenticated {
            await MainActor.run {
                self.delegate?.passcodeAuthenticated?(self)
                NotificationCenter.default.post(name: Passcode.PasscodeAuthenticatedNotification, object: self)
            }
        } else {
            await MainActor.run {
                self.delegate?.passcodeAuthenticationFaliure?(self)
                NotificationCenter.default.post(name: Passcode.PasscodeAuthenticationFaliureNotification, object: self)
            }
        }

        return authenticated
    }

    /// Returns whether a passcode has been set for this instance.
    ///
    /// Checks `UserDefaults` for the existence of a stored passcode hash under
    /// this instance's key.
    ///
    /// - Returns: `true` if a passcode hash exists in storage, `false` otherwise.
    @objc
    public func isPasscodeSet() -> Bool {
        UserDefaults.standard.object(forKey: self.userDefaultsKey) != nil
    }

    /// Returns whether the device supports biometric authentication.
    ///
    /// Evaluates whether the device has biometric hardware (Face ID, Touch ID, or
    /// Optic ID) available and properly configured. Any evaluation errors are printed
    /// to the debug console.
    ///
    /// - Returns: `true` if biometric authentication can be enabled, `false` otherwise.
    @objc
    public static func canEnableBiometrics() -> Bool {
        let context = LAContext()
        var error: NSError?
        let canEnableBiometrics = context.canEvaluatePolicy(.deviceOwnerAuthenticationWithBiometrics, error: &error)
        if let error {
            debugPrint(error)
        }

        return canEnableBiometrics
    }

    /// Enables or disables biometric authentication for passcode verification.
    ///
    /// When enabling, the method checks device capability and triggers a biometric
    /// prompt to confirm the user's identity before persisting the preference. When
    /// disabling, the preference is cleared immediately without a biometric prompt.
    /// The enabled state is stored in `UserDefaults` under the
    /// `net.domzilla.PasscodeKit.enableBiometrics` key.
    ///
    /// - Parameter enable: `true` to enable biometric authentication, `false` to disable it.
    /// - Returns: `true` if biometrics were successfully enabled, `false` otherwise.
    /// - Throws: An error from `LAContext` if biometrics are unavailable or evaluation fails
    ///   (including user cancellation).
    @objc
    public static func enableBiometrics(_ enable: Bool) async throws -> Bool {
        if enable {
            let context = LAContext()
            var error: NSError?
            let canEnableBiometrics = context.canEvaluatePolicy(.deviceOwnerAuthenticationWithBiometrics, error: &error)
            if let error {
                throw error
            }

            if canEnableBiometrics {
                let enabled = try await context.evaluatePolicy(
                    .deviceOwnerAuthenticationWithBiometrics,
                    localizedReason: NSLocalizedString(
                        "Enable biometric authentication",
                        bundle: Bundle.PasscodeKitRessourceBundle,
                        comment: "Biometric enrollment prompt reason"
                    )
                )
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

    /// Returns whether biometric authentication is currently enabled for passcode verification.
    ///
    /// Reads the persisted preference from `UserDefaults` under the
    /// `net.domzilla.PasscodeKit.enableBiometrics` key.
    ///
    /// - Returns: `true` if biometrics are enabled, `false` otherwise.
    @objc
    public static func isBiometricsEnabled() -> Bool {
        UserDefaults.standard.bool(forKey: "net.domzilla.PasscodeKit.enableBiometrics")
    }
}

// MARK: - Hash Import

@objc
extension Passcode {
    /// Directly stores a pre-computed hash as the passcode for the given key.
    ///
    /// This method bypasses the normal passcode creation flow and writes the provided
    /// hash directly into `UserDefaults`. The passcode option is set to `.alphanumerical`
    /// since the original code format cannot be inferred from a pre-computed hash.
    ///
    /// - Important: The hash must be in the same format produced by the framework's
    ///   internal hashing (lowercase hexadecimal SHA256 or MD5 digest).
    ///
    /// - Parameter hash: The pre-computed hash string to store as the passcode.
    /// - Parameter key: The unique passcode key under which to store the hash.
    public static func setHash(_ hash: String, forKey key: String) {
        let dict = [
            Passcode.hashKey: hash,
            Passcode.optionKey: PasscodeOption.alphanumerical.rawValue,
        ]
        let userDefaultsKey = Passcode.userDefaultsKey(key)
        UserDefaults.standard.setValue(dict, forKey: userDefaultsKey)
        UserDefaults.standard.synchronize()
    }
}

// MARK: - Private Helpers

extension Passcode {
    private func hash(_ string: String) -> String {
        let data = Data(string.utf8)
        let digest: any Digest = Passcode.legacyMD5Support ? Insecure.MD5.hash(data: data) : SHA256.hash(data: data)
        return digest.compactMap { String(format: "%02x", $0) }.joined()
    }

    private func option(for code: String) -> PasscodeOption {
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

    fileprivate static func userDefaultsKey(_ key: String) -> String {
        "net.domzilla.PasscodeKit." + key
    }
}
