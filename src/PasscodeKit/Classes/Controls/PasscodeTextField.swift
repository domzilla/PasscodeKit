//
//  PasscodeTextField.swift
//  PasscodeKit
//
//  Created by Dominic Rodemer on 12.10.24.
//

import UIKit

internal class PasscodeTextField: UITextField {

    private var _passcodeOption: PasscodeOption = .fourDigits
    var passcodeOption: PasscodeOption {
        get {
            return _passcodeOption
        }
        set {
            _passcodeOption = newValue
            
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
                let circlePath = UIBezierPath(arcCenter: circleCenter,
                                              radius: radius,
                                              startAngle: 0,
                                              endAngle: 2 * .pi,
                                              clockwise: false)
                
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
    
	private let radius: CGFloat = 8
	private let spacing: CGFloat = 20
    private var circleBackgroundLayer: CALayer = CALayer()
    
    init(frame: CGRect, passcodeOption: PasscodeOption) {
		super.init(frame: frame)
        
        self.borderStyle = .none
        self.layer.cornerRadius = 10.0
        self.textAlignment = .center
        self.isSecureTextEntry = true
        self.returnKeyType = .done
        
        self.passcodeOption = passcodeOption
        
        NotificationCenter.default.addObserver(self,
                                               selector: #selector(textDidChangeNotification(_:)),
                                               name: UITextField.textDidChangeNotification,
                                               object: self)
	}
    
    required init?(coder: NSCoder) {
        fatalError("init(coder:) has not been implemented")
    }
    
    deinit {
        NotificationCenter.default.removeObserver(self)
    }
        
	override func canPerformAction(_ action: Selector, withSender sender: Any?) -> Bool {
		return false
	}

	override func layoutSubviews() {
		super.layoutSubviews()
        
        if self.isNumericPasscode {
            let circles = CGFloat(self.passcodeOption.length)
            let circleBackgroundLayerWidth = (2 * radius * circles) + spacing * (circles - 1)
            self.circleBackgroundLayer.frame = CGRect(x: (self.frame.size.width - circleBackgroundLayerWidth) / 2.0,
                                                      y: (self.frame.size.height - 2 * radius) / 2.0,
                                                      width: circleBackgroundLayerWidth,
                                                      height: 2 * radius)
            
            if let circleLayers = self.circleBackgroundLayer.sublayers {
                for (i, circleLayer) in circleLayers.enumerated() {
                    circleLayer.frame = CGRect(x: (2 * radius + spacing) * CGFloat(i),
                                               y: 0,
                                               width: 2 * radius,
                                               height: 2 * radius)
                }
            }
        }
	}
    
    override func traitCollectionDidChange(_ previousTraitCollection: UITraitCollection?) {
        super.traitCollectionDidChange(previousTraitCollection)
        
        self.updateText()
    }
    
    func clear() {
        self.text = nil;
        self.updateText()
    }
}


private extension PasscodeTextField {
    
    var isNumericPasscode: Bool {
        return self.passcodeOption == .fourDigits || self.passcodeOption == .sixDigits
    }
    
    func updateText() {
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
    @objc func textDidChangeNotification(_ notification: Notification) {
        self.updateText()
    }
}
