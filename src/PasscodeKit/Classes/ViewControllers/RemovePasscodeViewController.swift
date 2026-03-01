//
//  RemovePasscodeViewController.swift
//  PasscodeKit
//
//  Created by Dominic Rodemer on 21.10.24.
//

import UIKit

/// A view controller that handles the passcode removal flow.
///
/// `RemovePasscodeViewController` prompts the user to enter their current passcode
/// to confirm removal. Upon successful authentication, the stored passcode hash and
/// associated passcode option are deleted from `UserDefaults`, effectively disabling
/// the passcode. If the entered passcode does not match, the user is shown an error
/// message with a shake animation and may try again.
///
/// This controller is presented modally inside a `UINavigationController` with a
/// cancel button, allowing the user to abort the removal without changes.
///
/// - Note: This class is internal to the framework and is not exposed as public API.
///   It is instantiated by `Passcode.remove(presentOn:animated:)`.
class RemovePasscodeViewController: PasscodeViewController {
    /// Creates a new remove-passcode view controller for the given passcode instance.
    ///
    /// Sets the navigation title to the localized "Remove Passcode" string.
    ///
    /// - Parameter passcode: The `Passcode` instance whose stored passcode will be
    ///   removed upon successful authentication.
    override init(passcode: Passcode) {
        super.init(passcode: passcode)

        self.title = NSLocalizedString(
            "Remove Passcode",
            bundle: Bundle.PasscodeKitRessourceBundle,
            comment: "Headline for 'Remove Passcode' view"
        )
    }

    /// Unavailable initializer required by `UIViewController` conformance.
    ///
    /// This view controller does not support initialization from a storyboard or nib.
    ///
    /// - Parameter coder: The unarchiver object. Not used.
    @available(*, unavailable)
    required init?(coder _: NSCoder) {
        fatalError("init(coder:) has not been implemented")
    }

    /// Configures the view after the controller's view is loaded into memory.
    ///
    /// Sets up the info label with a localized prompt instructing the user to enter
    /// their current passcode, configures the passcode text field with a "Done" return
    /// key type, and adds a cancel bar button item to the navigation bar's right side.
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
    /// Makes the passcode text field the first responder so the keyboard appears
    /// immediately when the view is presented.
    ///
    /// - Parameter animated: Whether the transition to the visible state is animated.
    override func viewWillAppear(_ animated: Bool) {
        super.viewWillAppear(animated)

        self.passcodeTextField.becomeFirstResponder()
    }

    /// Handles the event when the user submits a passcode entry.
    ///
    /// Asynchronously authenticates the entered passcode against the stored hash
    /// via `Passcode.authenticate(_:)`. If authentication succeeds, the passcode is
    /// removed from `UserDefaults` by calling `Passcode.remove()`, and the view
    /// controller is dismissed. If authentication fails, a localized error message
    /// is displayed in the failed label, a shake animation plays on the text field,
    /// and the text field is cleared so the user can retry.
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
                self.passcode.remove()
                self.dismiss(animated: true)
            }
        }
    }
}

// MARK: - Actions

extension RemovePasscodeViewController {
    /// Handles the cancel bar button item tap.
    ///
    /// Dismisses the remove-passcode view controller without modifying the stored
    /// passcode, allowing the user to abort the removal flow.
    ///
    /// - Parameter sender: The object that initiated the action. Not used.
    @objc
    private func cancelButtonAction(_: Any?) {
        self.dismiss(animated: true)
    }
}
