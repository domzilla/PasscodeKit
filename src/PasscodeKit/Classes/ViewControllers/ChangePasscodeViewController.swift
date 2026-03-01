//
//  ChangePasscodeViewController.swift
//  PasscodeKit
//
//  Created by Dominic Rodemer on 21.10.24.
//

import UIKit

/// Represents the discrete steps of the change-passcode flow.
///
/// The view controller progresses through these states sequentially:
/// first verifying the user's current passcode, then collecting a new passcode,
/// and finally confirming the new passcode matches.
private enum ChangePasscodeViewControllerState {
    /// The user must enter their existing passcode for verification.
    case enterOldPasscode

    /// The user enters a new passcode to replace the current one.
    case enterNewPasscode

    /// The user re-enters the new passcode to confirm it matches.
    case verifyNewPasscode
}

/// A view controller that guides the user through changing their existing passcode.
///
/// `ChangePasscodeViewController` implements a three-step state machine:
/// 1. **Enter old passcode** -- the user's current passcode is verified against the stored hash.
/// 2. **Enter new passcode** -- the user types a replacement passcode.
/// 3. **Verify new passcode** -- the user re-enters the new passcode for confirmation.
///
/// On successful completion the stored passcode hash is updated via `Passcode.create(_:)`
/// and the view controller is dismissed. If verification fails at any step a mismatch
/// error is displayed and the user may retry.
///
/// - Note: This controller is presented internally by `Passcode.change(presentOn:animated:)`
///   and is not part of the public API.
class ChangePasscodeViewController: PasscodeViewController {
    /// The current step in the change-passcode flow.
    ///
    /// Starts at `.enterOldPasscode` and advances to `.enterNewPasscode` and then
    /// `.verifyNewPasscode` as the user successfully completes each step.
    private var state: ChangePasscodeViewControllerState = .enterOldPasscode

    /// The new passcode entered during the `.enterNewPasscode` step.
    ///
    /// Temporarily stored so it can be compared against the confirmation entry
    /// in the `.verifyNewPasscode` step. Remains `nil` until the user completes
    /// the new-passcode step.
    private var code: String?

    /// Indicates whether the most recent passcode entry did not match the expected value.
    ///
    /// When `true`, the UI displays a localized error message informing the user that
    /// the passcodes do not match.
    private var mismatch = false

    /// Creates a new change-passcode view controller for the given passcode instance.
    ///
    /// Sets the navigation title to the localized "Change Passcode" string.
    ///
    /// - Parameter passcode: The `Passcode` instance whose stored passcode will be changed.
    override init(passcode: Passcode) {
        super.init(passcode: passcode)

        self.title = NSLocalizedString(
            "Change Passcode",
            bundle: Bundle.PasscodeKitRessourceBundle,
            comment: "Headline for 'Change Passcode' view"
        )
    }

    /// Unavailable. This view controller does not support instantiation from a storyboard or nib.
    ///
    /// - Parameter coder: The unarchiver object. Not used.
    @available(*, unavailable)
    required init?(coder _: NSCoder) {
        fatalError("init(coder:) has not been implemented")
    }

    /// Called after the view has been loaded into memory.
    ///
    /// Adds a cancel bar button to the navigation bar and performs the initial
    /// UI update to reflect the `.enterOldPasscode` state.
    override func viewDidLoad() {
        super.viewDidLoad()

        self.navigationItem.rightBarButtonItem = UIBarButtonItem(
            barButtonSystemItem: .cancel,
            target: self,
            action: #selector(cancelButtonAction(_:))
        )

        self.updateUI()
    }

    /// Called just before the view is added to a window.
    ///
    /// Makes the passcode text field the first responder so the keyboard
    /// appears immediately when the view is presented.
    ///
    /// - Parameter animated: Whether the transition to visible is animated.
    override func viewWillAppear(_ animated: Bool) {
        super.viewWillAppear(animated)

        self.passcodeTextField.becomeFirstResponder()
    }

    /// Handles passcode submission for the current step in the change-passcode flow.
    ///
    /// Behavior varies by state:
    /// - **`.enterOldPasscode`**: Asynchronously authenticates the entered text against
    ///   the stored passcode hash. On success, advances to `.enterNewPasscode`.
    ///   On failure, shows a shake animation and mismatch error.
    /// - **`.enterNewPasscode`**: Stores the entered text in `code`, resets the mismatch
    ///   flag, and advances to `.verifyNewPasscode`.
    /// - **`.verifyNewPasscode`**: Compares the entered text with the previously stored
    ///   `code`. If they match, persists the new passcode via `Passcode.create(_:)` and
    ///   dismisses the view controller. If they differ, shows a mismatch error.
    override func didEnterPasscode() {
        super.didEnterPasscode()

        if self.state == .enterOldPasscode {
            Task {
                var authenticated = false
                do {
                    authenticated = try await self.passcode.authenticate(self.passcodeTextField.text)
                } catch {
                    debugPrint(error)
                }

                self.mismatch = !authenticated
                self.passcodeTextField.clear()
                if !self.mismatch {
                    self.state = .enterNewPasscode
                    self.animatePasscodeTextField()
                } else {
                    self.animateFailure()
                }

                self.updateUI()
            }
        } else if self.state == .enterNewPasscode {
            self.code = self.passcodeTextField.text
            self.passcodeTextField.clear()
            self.mismatch = false
            self.animatePasscodeTextField()
            self.state = .verifyNewPasscode
            self.updateUI()
        } else if self.state == .verifyNewPasscode {
            if let code = self.code {
                if code == self.passcodeTextField.text {
                    self.passcode.create(code)
                    self.dismiss(animated: true)
                } else {
                    self.mismatch = true
                    self.passcodeTextField.clear()
                    self.animateFailure()
                    self.updateUI()
                }
            }
        }
    }
}

// MARK: - Private Helpers

extension ChangePasscodeViewController {
    /// Synchronizes the interface elements with the current state and mismatch flag.
    ///
    /// Updates the info label text, the return key type of the passcode text field,
    /// and the visibility of the passcode-option button. Also shows or hides the
    /// mismatch error label depending on whether the last entry was incorrect.
    ///
    /// - Note: The option button is only visible during the `.enterNewPasscode` step,
    ///   allowing the user to switch between four-digit, six-digit, and alphanumeric modes.
    private func updateUI() {
        self.optionButton.isHidden = true

        if self.state == .enterOldPasscode {
            self.infoLabel.text = NSLocalizedString(
                "Enter your passcode",
                bundle: Bundle.PasscodeKitRessourceBundle,
                comment: "Promt user to enter passcode"
            )
            self.passcodeTextField.returnKeyType = .next
            self.passcodeTextField.reloadInputViews()
        } else if self.state == .enterNewPasscode {
            self.infoLabel.text = NSLocalizedString(
                "Enter new passcode",
                bundle: Bundle.PasscodeKitRessourceBundle,
                comment: "Promt user to enter new passcode"
            )
            self.passcodeTextField.returnKeyType = .next
            self.passcodeTextField.reloadInputViews()
            self.optionButton.isHidden = false
        } else if self.state == .verifyNewPasscode {
            self.infoLabel.text = NSLocalizedString(
                "Verify new passcode",
                bundle: Bundle.PasscodeKitRessourceBundle,
                comment: "Promt user to verify new passcode"
            )
            self.passcodeTextField.returnKeyType = .done
            self.passcodeTextField.reloadInputViews()
        }

        if self.mismatch {
            self.setFailedLabelText(NSLocalizedString(
                "Passcodes don't match. Try again.",
                bundle: Bundle.PasscodeKitRessourceBundle,
                comment: "Notify user that passcodes do not match"
            ))
        } else {
            self.setFailedLabelText(nil)
        }
    }

    /// Animates the passcode text field sliding in from the side to indicate a state transition.
    ///
    /// The direction of the slide depends on the `mismatch` flag:
    /// - When `mismatch` is `false`, the text field slides in from the right (forward progression).
    /// - When `mismatch` is `true`, the text field slides in from the left (error / retry).
    private func animatePasscodeTextField() {
        let x = self.passcodeTextField.frame.origin.x
        self.passcodeTextField.frame.origin.x = x + (self.mismatch ? -250.0 : 250.0)
        UIView.animate(withDuration: 0.15) {
            self.passcodeTextField.frame.origin.x = x
        }
    }

    // MARK: - Actions

    /// Dismisses the change-passcode flow without saving any changes.
    ///
    /// Triggered by the cancel bar button item in the navigation bar.
    ///
    /// - Parameter sender: The object that initiated the action. Not used.
    @objc
    private func cancelButtonAction(_: Any?) {
        self.dismiss(animated: true)
    }
}
