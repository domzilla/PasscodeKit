//
//  AppPasscode.swift
//  PasscodeKit
//
//  Created by Dominic Rodemer on 22.10.24.
//

import UIKit

/// App-level passcode manager that provides automatic locking and unlocking of the entire application.
///
/// `AppPasscode` is a singleton subclass of `Passcode` designed for app-wide passcode protection.
/// When configured, it automatically locks all connected scenes when the app enters the background
/// and presents a lock screen by replacing each window's root view controller with a
/// `LockViewController`. Upon successful authentication, the original root view controllers
/// are restored.
///
/// - Important: Call `applicationDidFinishLaunching()` from your app delegate's
///   `application(_:didFinishLaunchingWithOptions:)` method to register the required
///   notification observers and perform the initial lock.
@objc
public class AppPasscode: Passcode {
    /// The shared singleton instance used for app-level passcode management.
    ///
    /// All app-level locking, unlocking, and authentication operations should be performed
    /// through this shared instance.
    @objc public static let shared = AppPasscode()

    /// The `UserDefaults` storage key identifier for the app-level passcode.
    private static let key = "AppPasscode.Key"

    /// A dictionary mapping window scene persistent identifiers to their original root view controllers.
    ///
    /// When the app is locked, each scene's root view controller is stored here so it can be
    /// restored after successful authentication.
    private var rootViewController: [String: UIViewController] = [:]

    /// Indicates whether the app is currently in a locked state.
    ///
    /// When `true`, the app's windows are displaying `LockViewController` instances
    /// in place of their original root view controllers.
    private var locked: Bool = false

    /// Creates a new `AppPasscode` instance using the default app-level storage key.
    ///
    /// - Note: In most cases, use the `shared` singleton rather than creating new instances.
    @objc
    public init() {
        super.init(key: AppPasscode.key)
    }

    /// Creates a new `AppPasscode` instance, ignoring the provided key in favor of the default app-level storage key.
    ///
    /// This override ensures that all `AppPasscode` instances use the same underlying storage key
    /// regardless of the key parameter passed in, maintaining consistency for app-level passcode data.
    ///
    /// - Parameter key: Ignored. The internal `AppPasscode.key` is always used.
    @objc
    override public init(key _: String) {
        super.init(key: AppPasscode.key)
    }

    /// Registers notification observers for app lifecycle events and performs the initial lock.
    ///
    /// This method must be called once during app startup, typically from
    /// `application(_:didFinishLaunchingWithOptions:)` in the app delegate. It registers
    /// observers for `UIApplication.willEnterForegroundNotification` and
    /// `UIApplication.didEnterBackgroundNotification` on the shared instance, locks the app
    /// immediately, and attempts biometric authentication if biometrics are enabled.
    ///
    /// - Important: Failing to call this method means the app will not auto-lock on
    ///   background transitions.
    @objc
    public static func applicationDidFinishLaunching() {
        NotificationCenter.default.addObserver(
            AppPasscode.shared,
            selector: #selector(applicationWillEnterForegroundNotification(_:)),
            name: UIApplication.willEnterForegroundNotification,
            object: nil
        )
        NotificationCenter.default.addObserver(
            AppPasscode.shared,
            selector: #selector(applicationDidEnterBackgroundNotification(_:)),
            name: UIApplication.didEnterBackgroundNotification,
            object: nil
        )

        AppPasscode.shared.lock()

        if Passcode.isBiometricsEnabled() {
            Task {
                do {
                    _ = try await AppPasscode.shared.authenticate(nil)
                } catch {
                    debugPrint(error)
                }
            }
        }
    }

    /// Locks the app by replacing each connected window scene's root view controller with a lock screen.
    ///
    /// If the app is already locked or no passcode has been set, this method returns immediately
    /// without taking any action. When locking, the method iterates through all connected
    /// `UIWindowScene` instances, stores each window's current root view controller for later
    /// restoration, and replaces it with a `LockViewController`.
    ///
    /// - Note: Only the first window with a root view controller in the first available
    ///   window scene is locked. The method returns after locking a single window.
    @objc
    public func lock() {
        if self.locked {
            return
        }

        if self.isPasscodeSet() {
            for scene in UIApplication.shared.connectedScenes {
                if let windowScene = scene as? UIWindowScene {
                    let lockViewController = LockViewController(passcode: self)
                    for window in windowScene.windows {
                        if let viewController = window.rootViewController {
                            self.rootViewController[windowScene.session.persistentIdentifier] = viewController
                            window.rootViewController = lockViewController
                            self.locked = true
                            return
                        }
                    }
                }
            }
        }
    }

    /// Locks the app, ignoring the provided view controller.
    ///
    /// This override redirects to the parameterless `lock()` method because `AppPasscode`
    /// always locks at the window level rather than overlaying a specific view controller.
    /// The `viewController` parameter is not used.
    ///
    /// - Parameter viewController: Ignored. App-level locking operates on window root view controllers.
    @objc
    override public func lock(_: UIViewController) {
        self.lock()
    }

    /// Authenticates the user and unlocks the app if authentication succeeds.
    ///
    /// If the app is not currently locked, this method returns `true` immediately without
    /// performing any authentication. Otherwise, it delegates to the superclass `authenticate(_:)`
    /// method to verify the provided passcode or perform biometric authentication (when `code`
    /// is `nil`). On successful authentication, the original root view controllers are restored
    /// on the main thread and the locked state is cleared.
    ///
    /// - Parameter code: The passcode string to verify, or `nil` to attempt biometric authentication.
    /// - Returns: `true` if authentication succeeded or the app was not locked, `false` otherwise.
    /// - Throws: An error if biometric evaluation fails or is unavailable.
    @objc
    override public func authenticate(_ code: String?) async throws -> Bool {
        if !self.locked {
            return true
        }

        let authenticated = try await super.authenticate(code)

        await MainActor.run {
            if authenticated {
                for scene in UIApplication.shared.connectedScenes {
                    if let windowScene = scene as? UIWindowScene {
                        for window in windowScene.windows {
                            if window.rootViewController is LockViewController {
                                if
                                    let viewController = self
                                        .rootViewController[windowScene.session.persistentIdentifier]
                                {
                                    window.rootViewController = viewController
                                    self.rootViewController
                                        .removeValue(forKey: windowScene.session.persistentIdentifier)
                                    break
                                }
                            }
                        }
                    }
                }
                self.locked = false
            }
        }

        return authenticated
    }
}

// MARK: - UIApplication Notifications

extension AppPasscode {
    /// Handles the app returning to the foreground by locking and attempting biometric authentication.
    ///
    /// This method is called in response to `UIApplication.willEnterForegroundNotification`.
    /// It locks the app immediately and, if biometrics are enabled, attempts automatic
    /// biometric authentication so the user can unlock without manually entering a passcode.
    ///
    /// - Parameter notification: The notification object posted by the system.
    @objc
    private func applicationWillEnterForegroundNotification(_: Notification) {
        self.lock()

        if Passcode.isBiometricsEnabled() {
            Task {
                do {
                    _ = try await self.authenticate(nil)
                } catch {
                    debugPrint(error)
                }
            }
        }
    }

    /// Handles the app entering the background by locking immediately.
    ///
    /// This method is called in response to `UIApplication.didEnterBackgroundNotification`.
    /// It ensures the app is locked before it becomes inactive, preventing unauthorized access
    /// if the user switches back to the app.
    ///
    /// - Parameter notification: The notification object posted by the system.
    @objc
    private func applicationDidEnterBackgroundNotification(_: Notification) {
        self.lock()
    }
}
