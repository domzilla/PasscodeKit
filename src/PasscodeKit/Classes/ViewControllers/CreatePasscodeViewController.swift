//
//  CreatePasscodeViewController.swift
//  PasscodeKit
//
//  Created by Dominic Rodemer on 21.10.24.
//

import UIKit

/// A view controller that guides the user through creating a new passcode.
///
/// `CreatePasscodeViewController` implements a two-step passcode creation flow:
/// 1. The user enters a new passcode.
/// 2. The user verifies the passcode by entering it a second time.
///
/// If the verification matches, the passcode is persisted via the associated `Passcode`
/// instance. If the entries do not match, the user is shown an error message and prompted
/// to re-enter the verification. The first step also displays an option button that allows
/// the user to switch between passcode types (4-digit, 6-digit, or alphanumeric).
///
/// This view controller is presented modally inside a `UINavigationController` and includes
/// a cancel button to dismiss the flow without creating a passcode.
class CreatePasscodeViewController: PasscodeViewController {
    /// The passcode string entered during the first step of the creation flow.
    ///
    /// This value is `nil` until the user completes the initial entry. Once set, the
    /// view controller transitions to the verification step and compares subsequent
    /// input against this stored value.
    private var code: String?

    /// Indicates whether the most recent verification attempt produced a mismatch.
    ///
    /// When `true`, the UI displays a localized error message informing the user that
    /// the passcodes did not match. Reset to `false` when the user successfully
    /// enters the initial passcode again.
    private var mismatch = false

    /// Creates a new `CreatePasscodeViewController` for the given passcode instance.
    ///
    /// Sets the navigation title to the localized "Create Passcode" string.
    ///
    /// - Parameter passcode: The `Passcode` instance that will store the newly created passcode hash.
    override init(passcode: Passcode) {
        super.init(passcode: passcode)

        self.title = NSLocalizedString(
            "Create Passcode",
            bundle: Bundle.PasscodeKitRessourceBundle,
            comment: "Headline for 'Create Passcode' view"
        )
    }

    /// Unavailable. This view controller does not support initialization from a storyboard or nib.
    @available(*, unavailable)
    required init?(coder _: NSCoder) {
        fatalError("init(coder:) has not been implemented")
    }

    /// Called after the view has been loaded into memory.
    ///
    /// Adds a cancel bar button item to the navigation bar and performs the initial
    /// UI update to display the "enter passcode" prompt.
    override func viewDidLoad() {
        super.viewDidLoad()

        self.navigationItem.rightBarButtonItem = UIBarButtonItem(
            barButtonSystemItem: .cancel,
            target: self,
            action: #selector(cancelButtonAction(_:))
        )

        self.updateUI()
    }

    /// Called just before the view appears on screen.
    ///
    /// Activates the passcode text field as the first responder so the keyboard
    /// is displayed immediately when the view appears.
    ///
    /// - Parameter animated: Whether the appearance transition is animated.
    override func viewWillAppear(_ animated: Bool) {
        super.viewWillAppear(animated)

        self.passcodeTextField.becomeFirstResponder()
    }

    /// Handles the completion of passcode entry from the text field.
    ///
    /// This method implements the two-step state machine for passcode creation:
    ///
    /// - **Step 1 (enter):** If `code` is `nil`, the entered text is stored as the
    ///   candidate passcode. The text field is cleared and animated to indicate the
    ///   transition to the verification step.
    /// - **Step 2 (verify):** If `code` is already set, the entered text is compared
    ///   against the stored candidate. On match, the passcode is created and persisted
    ///   via `Passcode.create(_:)`, and the view controller is dismissed. On mismatch,
    ///   the `mismatch` flag is set, a shake animation is played, and the user is
    ///   prompted to try verification again.
    override func didEnterPasscode() {
        super.didEnterPasscode()

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
        } else {
            self.code = self.passcodeTextField.text
            self.passcodeTextField.clear()
            self.mismatch = false
            self.animatePasscodeTextField()
            self.updateUI()
        }
    }
}

// MARK: - Private Helpers

extension CreatePasscodeViewController {
    /// Updates all UI elements to reflect the current step and mismatch state.
    ///
    /// In the initial entry step (`code` is `nil`), the info label displays "Enter your
    /// passcode", the option button is visible to allow passcode type switching, and the
    /// keyboard return key is set to `.next`. In the verification step (`code` is set),
    /// the info label displays "Verify your passcode", the option button is hidden, and
    /// the return key changes to `.done`.
    ///
    /// If `mismatch` is `true`, the failed label is shown with a localized mismatch
    /// message. Otherwise the failed label is hidden.
    private func updateUI() {
        self.optionButton.isHidden = true

        if self.code == nil {
            self.infoLabel.text = NSLocalizedString(
                "Enter your passcode",
                bundle: Bundle.PasscodeKitRessourceBundle,
                comment: "Promt user to enter passcode"
            )
            self.optionButton.isHidden = false
            self.passcodeTextField.returnKeyType = .next
            self.passcodeTextField.reloadInputViews()
        } else {
            self.infoLabel.text = NSLocalizedString(
                "Verify your passcode",
                bundle: Bundle.PasscodeKitRessourceBundle,
                comment: "Promt user to verify passcode"
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

    /// Animates the passcode text field sliding in from off-screen.
    ///
    /// The direction of the slide-in depends on the `mismatch` state: the text field
    /// slides in from the left when there was a mismatch (returning to the entry step),
    /// or from the right when transitioning forward to the verification step. The
    /// animation duration is 0.15 seconds.
    private func animatePasscodeTextField() {
        let x = self.passcodeTextField.frame.origin.x
        self.passcodeTextField.frame.origin.x = x + (self.mismatch ? -250.0 : 250.0)
        UIView.animate(withDuration: 0.15) {
            self.passcodeTextField.frame.origin.x = x
        }
    }

    // MARK: - Actions

    /// Dismisses the passcode creation flow without creating a passcode.
    ///
    /// Called when the user taps the cancel bar button item. The view controller
    /// is dismissed with animation and no passcode is stored.
    ///
    /// - Parameter sender: The object that initiated the action. Not used.
    @objc
    private func cancelButtonAction(_: Any?) {
        self.dismiss(animated: true)
    }
}
