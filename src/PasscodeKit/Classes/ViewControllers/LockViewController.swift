//
//  LockViewController.swift
//  PasscodeKit
//
//  Created by Dominic Rodemer on 21.10.24.
//

import UIKit

/// A view controller that presents a lock screen requiring passcode or biometric authentication
/// before the user can proceed.
///
/// `LockViewController` is used internally by `Passcode.lock(_:)` and `AppPasscode.lock()` to
/// block access to the underlying content until the user successfully authenticates. It inherits
/// the passcode input UI from `PasscodeViewController` and adds biometric authentication support
/// (Face ID, Touch ID, or Optic ID) along with failed attempt feedback.
///
/// When the associated `Passcode` instance posts a `PasscodeAuthenticatedNotification`, the lock
/// view controller automatically removes itself from its parent, restoring access to the content
/// beneath it.
///
/// - Note: This class is not intended for direct instantiation by consumers of the framework.
///   Use `Passcode.lock(_:)` or `AppPasscode.lock()` instead.
class LockViewController: PasscodeViewController {
    /// Initializes the lock view controller with the given passcode instance.
    ///
    /// Registers an observer for `PasscodeAuthenticatedNotification` so the lock screen
    /// can automatically dismiss itself when authentication succeeds from any source
    /// (passcode entry or biometric authentication).
    ///
    /// - Parameter passcode: The `Passcode` instance that manages the stored passcode
    ///   and handles authentication logic.
    override init(passcode: Passcode) {
        super.init(passcode: passcode)

        NotificationCenter.default.addObserver(
            self,
            selector: #selector(passcodeAuthenticatedNotification(notification:)),
            name: Passcode.PasscodeAuthenticatedNotification,
            object: passcode
        )
    }

    /// Unsupported initializer required by `NSCoding`.
    ///
    /// This view controller does not support creation from a storyboard or nib.
    ///
    /// - Parameter coder: The unarchiver object. Not used.
    @available(*, unavailable)
    required init?(coder _: NSCoder) {
        fatalError("init(coder:) has not been implemented")
    }

    /// Removes all notification observers when the view controller is deallocated.
    deinit {
        NotificationCenter.default.removeObserver(self)
    }

    /// Configures the lock screen UI after the view hierarchy has been loaded.
    ///
    /// Sets the info label to prompt the user for passcode entry and configures
    /// the passcode text field with a "Done" return key type.
    override func viewDidLoad() {
        super.viewDidLoad()

        self.infoLabel.text = NSLocalizedString(
            "Enter your passcode",
            bundle: Bundle.PasscodeKitRessourceBundle,
            comment: "Promt user to enter passcode"
        )

        self.passcodeTextField.returnKeyType = .done
        self.passcodeTextField.reloadInputViews()
    }

    /// Called just before the view appears on screen.
    ///
    /// If biometric authentication is not enabled, the keyboard is presented
    /// immediately by making the passcode text field the first responder. When
    /// biometrics are enabled, keyboard presentation is deferred until after the
    /// biometric prompt completes (handled in `viewDidAppear(_:)`).
    ///
    /// - Parameter animated: Whether the appearance transition is animated.
    override func viewWillAppear(_ animated: Bool) {
        super.viewWillAppear(animated)

        if !Passcode.isBiometricsEnabled() {
            self.passcodeTextField.becomeFirstResponder()
        }
    }

    /// Called after the view has fully appeared on screen.
    ///
    /// When biometric authentication is enabled and the passcode is not an `AppPasscode`
    /// instance, this method triggers a biometric authentication prompt (Face ID, Touch ID,
    /// or Optic ID) by calling `authenticate(nil)`. If biometric authentication fails or
    /// is cancelled, the keyboard is shown so the user can fall back to manual passcode entry.
    ///
    /// - Parameter animated: Whether the appearance transition was animated.
    /// - Note: `AppPasscode` handles its own biometric authentication during app lifecycle
    ///   transitions, so biometric prompts are skipped here to avoid duplicate prompts.
    override func viewDidAppear(_ animated: Bool) {
        super.viewDidAppear(animated)

        if Passcode.isBiometricsEnabled(), !(self.passcode is AppPasscode) {
            Task {
                var authenticated = false
                do {
                    authenticated = try await self.passcode.authenticate(nil)
                } catch {
                    debugPrint(error)
                }

                if !authenticated {
                    self.passcodeTextField.becomeFirstResponder()
                }
            }
        }
    }

    /// Handles the event when the user finishes entering a passcode.
    ///
    /// Authenticates the entered passcode text against the stored hash via
    /// `Passcode.authenticate(_:)`. If authentication fails, a localized error message
    /// is displayed in the failed label, a shake animation is played on the passcode
    /// text field, and the input is cleared for another attempt. If authentication
    /// succeeds, the failed label is hidden and the `PasscodeAuthenticatedNotification`
    /// triggers automatic dismissal of this view controller.
    override func didEnterPasscode() {
        super.didEnterPasscode()

        Task {
            var authenticated = false
            do {
                authenticated = try await self.passcode.authenticate(self.passcodeTextField.text)
            } catch {
                debugPrint(error)
            }

            if !authenticated {
                self.setFailedLabelText(NSLocalizedString(
                    "Passcodes don't match. Try again.",
                    bundle: Bundle.PasscodeKitRessourceBundle,
                    comment: "Notify user that passcodes do not match"
                ))
                self.animateFailure()
                self.passcodeTextField.clear()
            } else {
                self.setFailedLabelText(nil)
            }
        }
    }
}

// MARK: - Passcode Notifications

extension LockViewController {
    /// Handles the `PasscodeAuthenticatedNotification` posted by the associated `Passcode` instance.
    ///
    /// When authentication succeeds (either via passcode or biometrics), this method removes the
    /// lock view controller from its parent's view hierarchy, effectively unlocking the content
    /// beneath it. If the view controller has no parent (already removed), the notification is
    /// silently ignored.
    ///
    /// - Parameter notification: The notification object containing the authenticated `Passcode`
    ///   instance as its `object`.
    @objc
    private func passcodeAuthenticatedNotification(notification _: NSNotification) {
        if self.parent != nil {
            self.willMove(toParent: nil)
            self.view.removeFromSuperview()
            self.removeFromParent()
        }
    }
}
