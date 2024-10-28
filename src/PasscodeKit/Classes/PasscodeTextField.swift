//
//  PasscodeTextField.swift
//  PasscodeKit
//
//  Created by Dominic Rodemer on 12.10.24.
//

import UIKit

internal class PasscodeTextField: UITextField {

    let passcodeLength: Int
    
	private let radius: CGFloat = 8
	private let spacing: CGFloat = 20
    
    private var circleBackgroundLayer: CALayer
    init(frame: CGRect, passcodeLength: Int) {
        
        self.passcodeLength = passcodeLength
        
        self.circleBackgroundLayer = CALayer()
        
		super.init(frame: frame)

        self.tintColor = .clear
        self.textColor = .clear
        self.borderStyle = .none
        self.keyboardType = .numberPad
        self.font = UIFont.systemFont(ofSize: 0)
        
        self.layer.addSublayer(circleBackgroundLayer)
        
        let circleCenter = CGPoint(x: radius, y: radius)
        let circlePath = UIBezierPath(arcCenter: circleCenter, 
                                      radius: radius,
                                      startAngle: 0,
                                      endAngle: 2 * .pi,
                                      clockwise: false)
        
        for _ in 0..<self.passcodeLength {
            let circleLayer = CAShapeLayer()
            circleLayer.path = circlePath.cgPath
            circleLayer.fillColor = nil
            circleLayer.lineWidth = 1
            self.circleBackgroundLayer.addSublayer(circleLayer)
        }
        
        self.updateText()
        
        NotificationCenter.default.addObserver(self,
                                               selector: #selector(textDidChangeNotification(_:)),
                                               name: UITextField.textDidChangeNotification,
                                               object: self)
	}
    
    required init?(coder: NSCoder) {
        fatalError("init(coder:) has not been implemented")
    }
    
	override func canPerformAction(_ action: Selector, withSender sender: Any?) -> Bool {
		return false
	}

	override func layoutSubviews() {
		super.layoutSubviews()
        
        let circles = CGFloat(self.passcodeLength)
        let circleBackgroundLayerWidth = (2 * radius * circles) + spacing * (circles - 1)
        circleBackgroundLayer.frame = CGRect(x: (self.frame.size.width - circleBackgroundLayerWidth) / 2.0,
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
    
    func updateText() {
        let currentLength = self.text?.count ?? 0
        
        let circleColor = UIColor.label.cgColor
        
        if let circleLayers = self.circleBackgroundLayer.sublayers {
            for (i, circleLayer) in circleLayers.enumerated() {
                guard let shapeLayer = circleLayer as? CAShapeLayer else { continue }
                shapeLayer.fillColor = (i < currentLength) ? circleColor : nil
                shapeLayer.strokeColor = circleColor
            }
        }
        
        if currentLength >= self.passcodeLength {
            self.sendActions(for: .editingDidEndOnExit)
        }
    }
    
    @objc func textDidChangeNotification(_ notification: Notification) {
        self.updateText()
    }
}
