//
//  CreatePasscodeViewController.swift
//  PasscodeKit
//
//  Created by Dominic Rodemer on 21.10.24.
//

import UIKit

class CreatePasscodeViewController: PasscodeViewController {
    private var code: String?

    private var mismatch = false

    override init(passcode: Passcode) {
        super.init(passcode: passcode)

        self.title = NSLocalizedString(
            "Create Passcode",
            bundle: Bundle.PasscodeKitRessourceBundle,
            comment: "Headline for 'Create Passcode' view"
        )
    }

    @available(*, unavailable)
    required init?(coder _: NSCoder) {
        fatalError("init(coder:) has not been implemented")
    }

    override func viewDidLoad() {
        super.viewDidLoad()

        let cancelButton = UIBarButtonItem(
            barButtonSystemItem: .cancel,
            target: self,
            action: #selector(cancelButtonAction(_:))
        )
        cancelButton.accessibilityIdentifier = "CreatePasscodeViewController.cancelButton"
        self.navigationItem.rightBarButtonItem = cancelButton

        self.updateUI()
    }

    override func viewWillAppear(_ animated: Bool) {
        super.viewWillAppear(animated)

        self.passcodeTextField.becomeFirstResponder()
    }

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

    private func animatePasscodeTextField() {
        let x = self.passcodeTextField.frame.origin.x
        self.passcodeTextField.frame.origin.x = x + (self.mismatch ? -250.0 : 250.0)
        UIView.animate(withDuration: 0.15) {
            self.passcodeTextField.frame.origin.x = x
        }
    }

    // MARK: - Actions

    @objc
    private func cancelButtonAction(_: Any?) {
        self.dismiss(animated: true)
    }
}
