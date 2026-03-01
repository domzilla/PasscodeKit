//
//  PasscodeViewController.swift
//  PasscodeKit
//
//  Created by Dominic Rodemer on 21.10.24.
//

import UIKit

/// The internal base view controller for all passcode-related screens in PasscodeKit.
///
/// `PasscodeViewController` provides the shared UI layout and common behavior used by every
/// passcode flow in the framework. It constructs and manages a vertically centered container
/// view that holds:
/// - An informational label (`infoLabel`) describing what the user should do.
/// - A passcode text field (`passcodeTextField`) for numeric or alphanumeric entry.
/// - A failure label (`failedLabel`) shown when authentication or verification fails.
/// - An option button (`optionButton`) that lets the user switch between passcode formats.
///
/// The container view automatically repositions itself in response to keyboard show/hide
/// notifications so that the passcode entry UI remains centered in the visible area above the
/// keyboard.
///
/// Subclasses override ``didEnterPasscode()`` to implement flow-specific logic (authentication,
/// creation, change, or removal). The following concrete subclasses exist:
/// - `LockViewController` -- locks the screen and requires passcode or biometric authentication.
/// - `AuthenticateViewController` -- presents a modal passcode challenge with a completion handler.
/// - `CreatePasscodeViewController` -- guides the user through creating a new passcode.
/// - `ChangePasscodeViewController` -- guides the user through changing an existing passcode.
/// - `RemovePasscodeViewController` -- requires the current passcode before removing it.
///
/// - Note: This class is not intended to be used directly. Always use one of the subclasses.
class PasscodeViewController: UIViewController {
    /// The `Passcode` model instance that this view controller operates on.
    ///
    /// Subclasses use this property to perform authentication, creation, and removal operations.
    let passcode: Passcode

    /// The main container view that holds all passcode-related UI elements.
    ///
    /// This view is vertically centered between the top safe area inset and the keyboard,
    /// and is repositioned automatically when the keyboard appears or disappears.
    var containerView: UIView!

    /// The text field where the user enters their passcode.
    ///
    /// This is a custom `PasscodeTextField` that supports multiple passcode formats
    /// (four-digit, six-digit, and alphanumeric) and provides a dot-based secure entry UI
    /// for numeric modes.
    var passcodeTextField: PasscodeTextField!

    /// A label displayed above the passcode text field that instructs the user on what to do.
    ///
    /// Subclasses set this label's text to provide context-specific instructions such as
    /// "Enter your passcode" or "Verify your passcode".
    var infoLabel: UILabel!

    /// A rounded, red-background label that displays failure messages.
    ///
    /// This label is hidden by default and shown via ``setFailedLabelText(_:)`` when the
    /// user enters an incorrect passcode or when verification fails.
    var failedLabel: UILabel!

    /// A button that presents a menu allowing the user to switch between passcode format options.
    ///
    /// The menu offers three choices: 4-digit numeric, 6-digit numeric, and custom alphanumeric.
    /// This button is hidden by default and shown by subclasses during passcode creation flows
    /// where the user is allowed to choose their preferred format.
    var optionButton: UIButton!

    /// The current keyboard frame, used to calculate the vertical center position of the container view.
    ///
    /// Updated by keyboard show/hide notifications. Defaults to `CGRectZero` when no keyboard
    /// is visible.
    private var keyboardFrame: CGRect = CGRectZero

    /// Creates a new passcode view controller for the given passcode model.
    ///
    /// Registers observers for keyboard show and hide notifications so the container view
    /// can be repositioned as the keyboard appears and disappears.
    ///
    /// - Parameter passcode: The `Passcode` model instance that this view controller will operate on.
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

    /// Unavailable. This view controller does not support initialization from a storyboard or nib.
    @available(*, unavailable)
    required init?(coder _: NSCoder) {
        fatalError("init(coder:) has not been implemented")
    }

    /// Removes all notification observers when the view controller is deallocated.
    deinit {
        NotificationCenter.default.removeObserver(self)
    }

    /// Creates the view hierarchy for the passcode screen.
    ///
    /// Builds the complete UI programmatically, including:
    /// - A full-width container view that holds all child elements.
    /// - A centered info label at the top of the container.
    /// - A `PasscodeTextField` configured with the current passcode option.
    /// - A hidden failure label positioned below the text field.
    /// - A hidden option button with a menu for switching passcode formats.
    ///
    /// - Note: Subclasses should call `super.loadView()` and then customize the elements
    ///   (e.g., setting `infoLabel.text` or showing `optionButton`) in `viewDidLoad()`.
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

    /// Repositions the container view whenever the view's layout changes.
    ///
    /// Called by UIKit after the view controller's view lays out its subviews. This ensures
    /// the container view remains vertically centered between the top safe area and the
    /// keyboard after device rotation or other layout changes.
    override func viewDidLayoutSubviews() {
        super.viewDidLayoutSubviews()

        self.layoutContainerView()
    }

    /// Updates the failed label with the given text, or hides it if `nil` is passed.
    ///
    /// When a non-nil string is provided, the label becomes visible, its text is set, and
    /// the label is resized to fit the content with horizontal padding. When `nil` is passed,
    /// the label is hidden.
    ///
    /// - Parameter text: The failure message to display, or `nil` to hide the label.
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
    }

    /// Plays a horizontal shake animation on the passcode text field to indicate an incorrect entry.
    ///
    /// The animation moves the text field 10 points left and right twice with auto-reverse,
    /// providing immediate visual feedback that the entered passcode was wrong. The animation
    /// is automatically removed from the layer upon completion.
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

    /// Called when the user finishes entering a passcode.
    ///
    /// The base implementation is intentionally empty. Subclasses override this method to
    /// implement their specific passcode handling logic, such as authenticating against a
    /// stored hash, advancing to a verification step, or completing a passcode change flow.
    ///
    /// This method is triggered by both the text field's `editingDidEndOnExit` action and
    /// the `UITextFieldDelegate` method `textFieldShouldReturn(_:)`.
    func didEnterPasscode() {}
}

// MARK: - UITextFieldDelegate

/// Conformance to `UITextFieldDelegate` to handle the return key press on the passcode text field.
extension PasscodeViewController: UITextFieldDelegate {
    /// Handles the return key press by forwarding to ``didEnterPasscode()``.
    ///
    /// Always returns `false` to prevent the text field from processing the return key
    /// further, since passcode submission is handled entirely by ``didEnterPasscode()``.
    ///
    /// - Parameter _: The text field that received the return key press (unused).
    /// - Returns: `false` to prevent default return key behavior.
    func textFieldShouldReturn(_: UITextField) -> Bool {
        self.didEnterPasscode()
        return false
    }
}

// MARK: - Private Helpers

extension PasscodeViewController {
    /// Recalculates and sets the container view's vertical position.
    ///
    /// Centers the container view vertically within the available space between the top
    /// safe area inset and the top of the keyboard. When no keyboard is visible, the
    /// container centers within the full height below the safe area.
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

    /// Handles the `editingDidEndOnExit` control event from the passcode text field.
    ///
    /// Forwards the action to ``didEnterPasscode()`` so subclasses can process the entered
    /// passcode through a single unified entry point.
    ///
    /// - Parameter _: The sender of the action (unused).
    @objc
    private func passcodeTextFieldAction(_: Any?) {
        self.didEnterPasscode()
    }

    // MARK: - Keyboard Notifications

    /// Handles keyboard show and hide notifications to reposition the container view.
    ///
    /// Extracts the keyboard's end frame from the notification's `userInfo` dictionary and
    /// stores it in ``keyboardFrame``, then triggers a layout update so the container view
    /// remains centered in the visible area above the keyboard.
    ///
    /// - Parameter notification: The keyboard notification containing frame information in its `userInfo`.
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
