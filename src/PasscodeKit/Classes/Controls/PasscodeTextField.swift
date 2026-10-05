//
//  PasscodeTextField.swift
//  PasscodeKit
//
//  Created by Dominic Rodemer on 12.10.24.
//

import UIKit

class PasscodeTextField: UITextField {
    private var _passcodeOption: PasscodeOption = .fourDigits

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
                self.accessibilityValue = nil
            }

            self.reloadInputViews()
        }
    }

    private let radius: CGFloat = 8

    private let spacing: CGFloat = 20

    private var circleBackgroundLayer: CALayer = .init()

    init(frame: CGRect, passcodeOption: PasscodeOption) {
        super.init(frame: frame)

        self.borderStyle = .none
        self.layer.cornerRadius = 10.0
        self.textAlignment = .center
        self.isSecureTextEntry = true
        self.returnKeyType = .done

        self.accessibilityLabel = NSLocalizedString(
            "Passcode",
            tableName: "Accessibility",
            bundle: Bundle.PasscodeKitRessourceBundle,
            comment: "Accessibility label for the passcode input field"
        )
        self.accessibilityIdentifier = "PasscodeViewController.passcodeTextField"

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

    @available(*, unavailable)
    required init?(coder _: NSCoder) {
        fatalError("init(coder:) has not been implemented")
    }

    deinit {
        NotificationCenter.default.removeObserver(self)
    }

    /// No clipboard or edit actions on passcode input, for security.
    override func canPerformAction(_: Selector, withSender _: Any?) -> Bool {
        false
    }

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

    func clear() {
        self.text = nil
        self.updateText()
    }
}

extension PasscodeTextField {
    private var isNumericPasscode: Bool {
        self.passcodeOption == .fourDigits || self.passcodeOption == .sixDigits
    }

    /// Sends .editingDidEndOnExit once a numeric passcode is complete, so no submit button is needed.
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

        self.accessibilityValue = String(
            format: NSLocalizedString(
                "%1$ld of %2$ld digits entered",
                tableName: "Accessibility",
                bundle: Bundle.PasscodeKitRessourceBundle,
                comment: "Accessibility value announcing how many passcode digits have been entered"
            ),
            currentLength,
            self.passcodeOption.length
        )

        if currentLength >= self.passcodeOption.length {
            self.sendActions(for: .editingDidEndOnExit)
        }
    }

    // MARK: - UITextField Notifications

    @objc
    private func textDidChangeNotification(_: Notification) {
        self.updateText()
    }
}
