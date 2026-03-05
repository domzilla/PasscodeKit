//
//  PasscodeTextField.swift
//  PasscodeKit
//
//  Created by Dominic Rodemer on 12.10.24.
//

import UIKit

/// A custom text field that visually represents passcode input.
///
/// For numeric passcode options (four-digit and six-digit), the text field hides the
/// standard text rendering and instead draws a row of circle indicators. Each circle
/// is either filled or empty to reflect how many digits the user has entered. For
/// alphanumeric passcodes, the text field displays standard secure text input with
/// a rounded background.
///
/// This class automatically triggers the `editingDidEndOnExit` control event when a
/// numeric passcode reaches its expected length, allowing the parent view controller
/// to respond immediately without a submit button.
class PasscodeTextField: UITextField {
    /// Backing storage for the current passcode option.
    private var _passcodeOption: PasscodeOption = .fourDigits

    /// The passcode option that determines the input mode and visual presentation.
    ///
    /// Setting this property reconfigures the text field's appearance and keyboard type.
    /// For numeric options (`.fourDigits`, `.sixDigits`), the text field creates circle
    /// indicator sublayers and hides the standard text rendering. For `.alphanumerical`,
    /// it displays a standard secure text field with a filled background.
    var passcodeOption: PasscodeOption {
        get {
            self._passcodeOption
        }
        set {
            self._passcodeOption = newValue

            self.circleBackgroundLayer.removeFromSuperlayer()

            if self.isNumericPasscode {
                self.circleBackgroundLayer = CALayer()
                self.layer.addSublayer(self.circleBackgroundLayer)

                self.tintColor = .clear
                self.textColor = .clear
                self.backgroundColor = .clear
                self.keyboardType = .numberPad
                self.font = UIFont.systemFont(ofSize: 0)

                let circleCenter = CGPoint(x: radius, y: radius)
                let circlePath = UIBezierPath(
                    arcCenter: circleCenter,
                    radius: radius,
                    startAngle: 0,
                    endAngle: 2 * .pi,
                    clockwise: false
                )

                for _ in 0..<self.passcodeOption.length {
                    let circleLayer = CAShapeLayer()
                    circleLayer.path = circlePath.cgPath
                    circleLayer.fillColor = nil
                    circleLayer.lineWidth = 1
                    self.circleBackgroundLayer.addSublayer(circleLayer)
                }

                self.updateText()
            } else {
                self.tintColor = nil
                self.textColor = .label
                self.backgroundColor = .secondarySystemFill
                self.keyboardType = .default
                self.font = UIFont.boldSystemFont(ofSize: 22)
            }

            self.reloadInputViews()
        }
    }

    /// The radius of each circle indicator in points.
    private let radius: CGFloat = 8

    /// The horizontal spacing between adjacent circle indicators in points.
    private let spacing: CGFloat = 20

    /// The container layer that holds all individual circle indicator sublayers.
    ///
    /// This layer is centered horizontally and vertically within the text field
    /// during layout. It is removed and recreated whenever `passcodeOption` changes.
    private var circleBackgroundLayer: CALayer = .init()

    /// Creates a new passcode text field with the specified frame and passcode option.
    ///
    /// The text field is configured with no border, centered text alignment, secure
    /// text entry enabled, and a done return key. It observes its own
    /// `textDidChangeNotification` to update the circle indicators in real time.
    ///
    /// - Parameter frame: The frame rectangle for the text field.
    /// - Parameter passcodeOption: The passcode option that determines input mode and visual style.
    init(frame: CGRect, passcodeOption: PasscodeOption) {
        super.init(frame: frame)

        self.borderStyle = .none
        self.layer.cornerRadius = 10.0
        self.textAlignment = .center
        self.isSecureTextEntry = true
        self.returnKeyType = .done

        self.passcodeOption = passcodeOption

        self.registerForTraitChanges([UITraitUserInterfaceStyle.self]) { (
            textField: PasscodeTextField,
            _: UITraitCollection
        ) in
            textField.updateText()
        }

        NotificationCenter.default.addObserver(
            self,
            selector: #selector(textDidChangeNotification(_:)),
            name: UITextField.textDidChangeNotification,
            object: self
        )
    }

    /// Unavailable. This class does not support initialization from a storyboard or nib.
    @available(*, unavailable)
    required init?(coder _: NSCoder) {
        fatalError("init(coder:) has not been implemented")
    }

    /// Removes the text field as an observer from `NotificationCenter` on deallocation.
    deinit {
        NotificationCenter.default.removeObserver(self)
    }

    /// Disables all edit menu actions (cut, copy, paste, select, etc.) for the text field.
    ///
    /// Passcode input should not allow clipboard interactions for security reasons.
    ///
    /// - Parameter action: The selector identifying the requested action.
    /// - Parameter sender: The object that initiated the action request.
    /// - Returns: Always returns `false` to prevent all edit actions.
    override func canPerformAction(_: Selector, withSender _: Any?) -> Bool {
        false
    }

    /// Lays out the circle indicator sublayers for numeric passcode modes.
    ///
    /// Centers the `circleBackgroundLayer` horizontally and vertically within the
    /// text field bounds, then positions each individual circle sublayer with
    /// equal spacing. This method has no effect for alphanumeric passcodes.
    override func layoutSubviews() {
        super.layoutSubviews()

        if self.isNumericPasscode {
            let circles = CGFloat(self.passcodeOption.length)
            let circleBackgroundLayerWidth = (2 * self.radius * circles) + self.spacing * (circles - 1)
            self.circleBackgroundLayer.frame = CGRect(
                x: (self.frame.size.width - circleBackgroundLayerWidth) / 2.0,
                y: (self.frame.size.height - 2 * self.radius) / 2.0,
                width: circleBackgroundLayerWidth,
                height: 2 * self.radius
            )

            if let circleLayers = self.circleBackgroundLayer.sublayers {
                for (i, circleLayer) in circleLayers.enumerated() {
                    circleLayer.frame = CGRect(
                        x: (2 * self.radius + self.spacing) * CGFloat(i),
                        y: 0,
                        width: 2 * self.radius,
                        height: 2 * self.radius
                    )
                }
            }
        }
    }

    /// Clears the text field content and resets all circle indicators to their empty state.
    func clear() {
        self.text = nil
        self.updateText()
    }
}

/// Private helpers for numeric passcode rendering and text change handling.
extension PasscodeTextField {
    /// Indicates whether the current passcode option uses a numeric input mode.
    ///
    /// Returns `true` for `.fourDigits` and `.sixDigits`, which display circle
    /// indicators instead of standard text. Returns `false` for `.alphanumerical`.
    private var isNumericPasscode: Bool {
        self.passcodeOption == .fourDigits || self.passcodeOption == .sixDigits
    }

    /// Updates the visual state of the circle indicators based on the current text length.
    ///
    /// For each circle sublayer, this method fills it if its index is less than the
    /// number of characters entered and leaves it empty otherwise. The fill and stroke
    /// colors adapt to the current user interface style (black for light mode, white
    /// for dark mode).
    ///
    /// When the entered text reaches the expected passcode length, this method
    /// automatically sends the `editingDidEndOnExit` action to notify listeners
    /// that the passcode entry is complete.
    ///
    /// - Note: This method returns immediately without any effect for alphanumeric passcodes.
    private func updateText() {
        if !self.isNumericPasscode {
            return
        }

        let currentLength = self.text?.count ?? 0
        if let circleLayers = self.circleBackgroundLayer.sublayers {
            var circleColor = UIColor.black.cgColor
            if self.traitCollection.userInterfaceStyle == .dark {
                circleColor = UIColor.white.cgColor
            }

            for (i, circleLayer) in circleLayers.enumerated() {
                guard let shapeLayer = circleLayer as? CAShapeLayer else { continue }
                shapeLayer.fillColor = (i < currentLength) ? circleColor : nil
                shapeLayer.strokeColor = circleColor
            }
        }

        if currentLength >= self.passcodeOption.length {
            self.sendActions(for: .editingDidEndOnExit)
        }
    }

    // MARK: - UITextField Notifications

    /// Handles the `UITextField.textDidChangeNotification` to refresh the circle indicators.
    ///
    /// Called whenever the text field's content changes, ensuring the visual state
    /// of the circle indicators stays in sync with the current input.
    ///
    /// - Parameter notification: The notification object containing the text change event.
    @objc
    private func textDidChangeNotification(_: Notification) {
        self.updateText()
    }
}
