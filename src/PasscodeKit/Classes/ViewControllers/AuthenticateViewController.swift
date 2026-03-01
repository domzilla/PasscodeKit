//
//  AuthenticateViewController.swift
//  PasscodeKit
//
//  Created by Dominic Rodemer on 30.04.25.
//

import UIKit

/// A view controller that handles modal passcode authentication.
///
/// `AuthenticateViewController` is presented modally (wrapped in a `UINavigationController`)
/// by `Passcode.authenticate(presentOn:animated:handler:)`. It prompts the user to enter
/// their passcode and optionally attempts biometric authentication when the view appears.
///
/// Unlike `LockViewController`, which overlays a parent view controller to block access
/// entirely, this controller is presented modally and includes a cancel button that allows
/// the user to dismiss the authentication flow without authenticating.
///
/// The result of the authentication attempt is delivered through the `authenticationHandler`
/// closure: `true` on success, `false` on cancellation or failure.
///
/// - Note: This class is internal to the PasscodeKit framework and is not part of the public API.
class AuthenticateViewController: PasscodeViewController {
    /// The closure invoked with the result of the authentication attempt.
    ///
    /// Called with `true` when the user successfully authenticates via passcode entry or
    /// biometrics, or `false` when the user taps the cancel button.
    let authenticationHandler: AuthenticationHandler

    /// Creates a new authenticate view controller with the given passcode and completion handler.
    ///
    /// - Parameter passcode: The `Passcode` instance to authenticate against. This determines
    ///   which stored passcode hash is compared and whether biometric authentication is attempted.
    /// - Parameter authenticationHandler: A closure called with the authentication result.
    ///   Receives `true` on successful authentication or `false` on cancellation.
    init(passcode: Passcode, authenticationHandler: @escaping AuthenticationHandler) {
        self.authenticationHandler = authenticationHandler

        super.init(passcode: passcode)
    }

    /// Unavailable. This view controller does not support storyboard or XIB initialization.
    ///
    /// - Parameter coder: The unarchiver object.
    /// - Returns: This initializer always triggers a fatal error.
    @available(*, unavailable)
    required init?(coder _: NSCoder) {
        fatalError("init(coder:) has not been implemented")
    }

    /// Removes the view controller as a notification observer upon deallocation.
    deinit {
        NotificationCenter.default.removeObserver(self)
    }

    /// Configures the view after it has been loaded into memory.
    ///
    /// Sets the info label to prompt the user for passcode entry, configures the text field
    /// return key to display "Done", and adds a cancel bar button item to the navigation bar.
    override func viewDidLoad() {
        super.viewDidLoad()

        self.infoLabel.text = NSLocalizedString(
            "Enter your passcode",
            bundle: Bundle.PasscodeKitRessourceBundle,
            comment: "Promt user to enter passcode"
        )

        self.passcodeTextField.returnKeyType = .done
        self.passcodeTextField.reloadInputViews()

        self.navigationItem.rightBarButtonItem = UIBarButtonItem(
            barButtonSystemItem: .cancel,
            target: self,
            action: #selector(cancelButtonAction(_:))
        )
    }

    /// Called just before the view is added to the view hierarchy.
    ///
    /// If biometric authentication is not enabled, the passcode text field becomes the
    /// first responder immediately so the keyboard appears when the view is shown.
    /// When biometrics are enabled, keyboard focus is deferred to `viewDidAppear(_:)`
    /// to allow the biometric prompt to appear first.
    ///
    /// - Parameter animated: Whether the transition to this view controller is animated.
    override func viewWillAppear(_ animated: Bool) {
        super.viewWillAppear(animated)

        if !Passcode.isBiometricsEnabled() {
            self.passcodeTextField.becomeFirstResponder()
        }
    }

    /// Called after the view has been fully transitioned onto screen.
    ///
    /// When biometric authentication is enabled and the passcode is not an `AppPasscode`,
    /// this method triggers a biometric authentication attempt by calling
    /// `passcode.authenticate(nil)`. If biometric authentication succeeds, the
    /// `authenticationHandler` is called with `true` and the view controller is dismissed.
    /// If it fails, the passcode text field becomes the first responder so the user can
    /// fall back to manual passcode entry.
    ///
    /// - Parameter animated: Whether the transition to this view controller was animated.
    /// - Note: Biometric authentication is skipped for `AppPasscode` instances because
    ///   app-level passcodes use a different authentication flow via `LockViewController`.
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
                } else {
                    self.authenticationHandler(true)
                    self.dismiss(animated: true)
                }
            }
        }
    }

    /// Called when the user finishes entering a passcode via the text field.
    ///
    /// Authenticates the entered passcode against the stored hash by calling
    /// `passcode.authenticate(_:)`. On success, clears any failure message, invokes
    /// the `authenticationHandler` with `true`, and dismisses the view controller.
    /// On failure, displays a localized error message, plays a shake animation on the
    /// passcode text field, and clears the input for another attempt.
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
                self.authenticationHandler(true)
                self.dismiss(animated: true)
            }
        }
    }
}

// MARK: - Actions

extension AuthenticateViewController {
    /// Handles the cancel bar button item tap.
    ///
    /// Invokes the `authenticationHandler` with `false` to indicate that the user
    /// cancelled the authentication flow, then dismisses the view controller.
    ///
    /// - Parameter sender: The object that initiated the action. Not used.
    @objc
    private func cancelButtonAction(_: Any?) {
        self.authenticationHandler(false)
        self.dismiss(animated: true)
    }
}
