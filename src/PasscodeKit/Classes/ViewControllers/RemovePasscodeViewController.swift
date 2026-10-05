//
//  RemovePasscodeViewController.swift
//  PasscodeKit
//
//  Created by Dominic Rodemer on 21.10.24.
//

import UIKit

class RemovePasscodeViewController: PasscodeViewController {
    override init(passcode: Passcode) {
        super.init(passcode: passcode)

        self.title = NSLocalizedString(
            "Remove Passcode",
            bundle: Bundle.PasscodeKitRessourceBundle,
            comment: "Headline for 'Remove Passcode' view"
        )
    }

    @available(*, unavailable)
    required init?(coder _: NSCoder) {
        fatalError("init(coder:) has not been implemented")
    }

    override func viewDidLoad() {
        super.viewDidLoad()

        self.infoLabel.text = NSLocalizedString(
            "Enter your passcode",
            bundle: Bundle.PasscodeKitRessourceBundle,
            comment: "Promt user to enter passcode"
        )

        self.passcodeTextField.returnKeyType = .done
        self.passcodeTextField.reloadInputViews()

        let cancelButton = UIBarButtonItem(
            barButtonSystemItem: .cancel,
            target: self,
            action: #selector(cancelButtonAction(_:))
        )
        cancelButton.accessibilityIdentifier = "RemovePasscodeViewController.cancelButton"
        self.navigationItem.rightBarButtonItem = cancelButton
    }

    override func viewWillAppear(_ animated: Bool) {
        super.viewWillAppear(animated)

        self.passcodeTextField.becomeFirstResponder()
    }

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
    @objc
    private func cancelButtonAction(_: Any?) {
        self.dismiss(animated: true)
    }
}
