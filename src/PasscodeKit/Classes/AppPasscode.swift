//
//  AppPasscode.swift
//  PasscodeKit
//
//  Created by Dominic Rodemer on 22.10.24.
//

import UIKit

@objc public class AppPasscode : Passcode {
    
    @objc public static let shared = AppPasscode()
    
    private static let key = "AppPasscode.Key"
    
    private var rootViewController: [String: UIViewController] = [:]
    private var locked: Bool = false
    
    @objc public init() {
        super.init(key: AppPasscode.key)
    }
        
    @objc public override init(key: String) {
        super.init(key: AppPasscode.key)
    }
    
    @objc public static func applicationDidFinishLaunching () {
        NotificationCenter.default.addObserver(AppPasscode.shared,
                                               selector: #selector(applicationWillEnterForegroundNotification(_:)),
                                               name: UIApplication.willEnterForegroundNotification,
                                               object: nil)
        NotificationCenter.default.addObserver(AppPasscode.shared,
                                               selector: #selector(applicationDidEnterBackgroundNotification(_:)),
                                               name: UIApplication.didEnterBackgroundNotification,
                                               object: nil)
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
        
    @objc public func lock() {
        if self.locked {
            return
        }
        
        if self.isPasscodeSet() {
            self.locked = true
            for scene in UIApplication.shared.connectedScenes {
                if let windowScene = scene as? UIWindowScene {
                    let lockViewController = LockViewController(passcode: self)
                    for window in windowScene.windows {
                        if let viewController = window.rootViewController {
                            self.rootViewController[windowScene.session.persistentIdentifier] = viewController
                            window.rootViewController = lockViewController
                            break
                        }
                    }
                }
            }
        }
    }
    
    @objc public override func lock(_ viewController: UIViewController) {
        self.lock()
    }
    
    @objc public override func authenticate(_ code: String?) async throws -> Bool {
        if !self.locked {
            return true
        }
        
        let authenticated = try await super.authenticate(code)
        
        DispatchQueue.main.async {
            if authenticated {
                for scene in UIApplication.shared.connectedScenes {
                    if let windowScene = scene as? UIWindowScene {
                        for window in windowScene.windows {
                            if window.rootViewController is LockViewController {
                                if let viewController = self.rootViewController[windowScene.session.persistentIdentifier] {
                                    window.rootViewController = viewController
                                    self.rootViewController.removeValue(forKey: windowScene.session.persistentIdentifier)
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


private extension AppPasscode {
    
    // MARK: - UIApplication Notifications
    @objc func applicationWillEnterForegroundNotification(_ notification: Notification) {
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
    
    @objc func applicationDidEnterBackgroundNotification(_ notification: Notification) {
        self.lock()
    }
}
