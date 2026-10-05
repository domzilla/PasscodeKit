//
//  PasscodeViewController.swift
//  PasscodeKit
//
//  Created by Dominic Rodemer on 21.10.24.
//

import UIKit

class PasscodeViewController: UIViewController {
    let passcode: Passcode

    var containerView: UIView!

    var passcodeTextField: PasscodeTextField!

    var infoLabel: UILabel!

    var failedLabel: UILabel!

    var optionButton: UIButton!

    private var keyboardFrame: CGRect = CGRectZero

    init(passcode: Passcode) {
        self.passcode = passcode

        super.init(nibName: nil, bundle: nil)

        NotificationCenter.default.addObserver(
            self,
            selector: #selector(keyboardNotification(_:)),
            name: UIResponder.keyboardWillShowNotification,
            object: nil
        )
        NotificationCenter.default.addObserver(
            self,
            selector: #selector(keyboardNotification(_:)),
            name: UIResponder.keyboardWillHideNotification,
            object: nil
        )
    }

    @available(*, unavailable)
    required init?(coder _: NSCoder) {
        fatalError("init(coder:) has not been implemented")
    }

    deinit {
        NotificationCenter.default.removeObserver(self)
    }

    override func loadView() {
        super.loadView()

        self.view.backgroundColor = .systemBackground

        self.containerView = UIView(frame: CGRect(x: 0.0, y: 0.0, width: self.view.frame.width, height: 120.0))
        self.view.addSubview(self.containerView)

        self.infoLabel = UILabel(frame: CGRect(x: 0.0, y: 0.0, width: self.containerView.frame.width, height: 30.0))
        self.infoLabel.autoresizingMask = .flexibleWidth
        self.infoLabel.textAlignment = .center
        self.infoLabel.textColor = .label
        self.infoLabel.font = UIFont.systemFont(ofSize: 17)
        self.infoLabel.accessibilityIdentifier = "PasscodeViewController.infoLabel"
        self.containerView.addSubview(self.infoLabel)

        self.passcodeTextField = PasscodeTextField(
            frame: CGRect(x: self.containerView.frame.width / 2.0 - 240.0 / 2.0, y: 35.0, width: 240.0, height: 50.0),
            passcodeOption: self.passcode.option
        )
        self.passcodeTextField.autoresizingMask = [.flexibleLeftMargin, .flexibleRightMargin]
        self.passcodeTextField.addTarget(
            self,
            action: #selector(passcodeTextFieldAction(_:)),
            for: .editingDidEndOnExit
        )
        self.passcodeTextField.delegate = self
        self.containerView.addSubview(self.passcodeTextField)

        self.failedLabel = UILabel(frame: CGRect(x: 0.0, y: 85.0, width: 0.0, height: 0.0))
        self.failedLabel.autoresizingMask = [.flexibleLeftMargin, .flexibleRightMargin]
        self.failedLabel.textAlignment = .center
        self.failedLabel.textColor = .white
        self.failedLabel.backgroundColor = .systemRed
        self.failedLabel.font = UIFont.systemFont(ofSize: 15)
        self.failedLabel.layer.cornerRadius = 15
        self.failedLabel.isHidden = true
        self.failedLabel.clipsToBounds = true
        self.failedLabel.accessibilityIdentifier = "PasscodeViewController.failedLabel"
        self.containerView.addSubview(self.failedLabel)

        var optionButtonConfiguration = UIButton.Configuration.plain()
        optionButtonConfiguration.title = NSLocalizedString(
            "Code options",
            bundle: Bundle.PasscodeKitRessourceBundle,
            comment: "Title for code options button"
        )
        self.optionButton = UIButton(configuration: optionButtonConfiguration)
        self.optionButton.autoresizingMask = [.flexibleLeftMargin, .flexibleRightMargin]
        self.optionButton.changesSelectionAsPrimaryAction = false
        self.optionButton.showsMenuAsPrimaryAction = true
        self.optionButton.accessibilityHint = NSLocalizedString(
            "Chooses the passcode format.",
            tableName: "Accessibility",
            bundle: Bundle.PasscodeKitRessourceBundle,
            comment: "Accessibility hint for the code options button"
        )
        self.optionButton.accessibilityIdentifier = "PasscodeViewController.optionButton"
        self.optionButton.menu = UIMenu(children: [
            UIAction(
                title: NSLocalizedString(
                    "4-Digit Numeric Code",
                    bundle: Bundle
                        .PasscodeKitRessourceBundle,
                    comment: "Code option: 4-digit numeric"
                ),
                handler: { _ in
                    self.passcodeTextField.passcodeOption = .fourDigits
                }
            ),
            UIAction(
                title: NSLocalizedString(
                    "6-Digit Numeric Code",
                    bundle: Bundle
                        .PasscodeKitRessourceBundle,
                    comment: "Code option: 6-digit numeric"
                ),
                handler: { _ in
                    self.passcodeTextField.passcodeOption = .sixDigits
                }
            ),
            UIAction(
                title: NSLocalizedString(
                    "Custom Alphanumeric Code",
                    bundle: Bundle
                        .PasscodeKitRessourceBundle,
                    comment: "Code option: custom alphanumeric"
                ),
                handler: { _ in
                    self.passcodeTextField.passcodeOption = .alphanumerical
                }
            ),
        ])
        self.optionButton.sizeToFit()
        self.optionButton.frame = CGRect(
            x: self.containerView.frame.width / 2.0 - self.optionButton.frame.width / 2.0,
            y: 85.0,
            width: self.optionButton.frame.width,
            height: 30.0
        )
        self.optionButton.isHidden = true
        self.containerView.addSubview(self.optionButton)
    }

    override func viewDidLayoutSubviews() {
        super.viewDidLayoutSubviews()

        self.layoutContainerView()
    }

    func setFailedLabelText(_ text: String?) {
        self.failedLabel.isHidden = text == nil

        self.failedLabel.text = text
        self.failedLabel.sizeToFit()
        self.failedLabel.frame = CGRect(
            x: self.containerView.frame.width / 2.0 - (self.failedLabel.frame.width + 30.0) / 2.0,
            y: self.failedLabel.frame.origin.y,
            width: self.failedLabel.frame.width + 30.0,
            height: 30.0
        )

        if let text {
            UIAccessibility.post(notification: .announcement, argument: text)
        }
    }

    func animateFailure() {
        let animation = CABasicAnimation(keyPath: "position")
        animation.duration = 0.09
        animation.repeatCount = 2
        animation.isRemovedOnCompletion = true
        animation.autoreverses = true
        animation.fromValue = CGPoint(x: self.passcodeTextField.center.x - 10, y: self.passcodeTextField.center.y)
        animation.toValue = CGPoint(x: self.passcodeTextField.center.x + 10, y: self.passcodeTextField.center.y)
        self.passcodeTextField.layer.add(animation, forKey: "position")
    }

    /// Subclass hook, called from both editingDidEndOnExit and textFieldShouldReturn(_:).
    func didEnterPasscode() {}
}

// MARK: - UITextFieldDelegate

extension PasscodeViewController: UITextFieldDelegate {
    func textFieldShouldReturn(_: UITextField) -> Bool {
        self.didEnterPasscode()
        return false
    }
}

// MARK: - Private Helpers

extension PasscodeViewController {
    private func layoutContainerView() {
        self.containerView.frame = CGRect(
            x: 0.0,
            y: self.view.safeAreaInsets
                .top +
                (self.view.frame.height - self.view.safeAreaInsets.top - self.keyboardFrame
                    .height) / 2.0 - self.containerView.frame.height / 2.0,
            width: self.view.frame.width,
            height: self.containerView.frame.height
        )
    }

    // MARK: - Actions

    @objc
    private func passcodeTextFieldAction(_: Any?) {
        self.didEnterPasscode()
    }

    // MARK: - Keyboard Notifications

    @objc
    private func keyboardNotification(_ notification: Notification) {
        if let userInfo = notification.userInfo {
            if let frameValue = userInfo[UIResponder.keyboardFrameEndUserInfoKey] as? NSValue {
                self.keyboardFrame = frameValue.cgRectValue
                self.layoutContainerView()
            }
        }
    }
}
