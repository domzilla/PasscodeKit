//
//  PasscodeViewController.swift
//  PasscodeKit
//
//  Created by Dominic Rodemer on 21.10.24.
//

import UIKit

internal class PasscodeViewController: UIViewController {
    
    let passcode: Passcode
    
    var containerView: UIView!
    var passcodeTextField: PasscodeTextField!
    var infoLabel: UILabel!
    var failedLabel: UILabel!
    
    private var keyboardFrame: CGRect = CGRectZero
    
    init(passcode: Passcode) {
        
        self.passcode = passcode
        
        super.init(nibName: nil, bundle: nil)
        
        NotificationCenter.default.addObserver(self, selector: #selector(keyboardNotification(_:)), name: UIResponder.keyboardWillShowNotification, object: nil)
        NotificationCenter.default.addObserver(self, selector: #selector(keyboardNotification(_:)), name: UIResponder.keyboardWillHideNotification, object: nil)
    }
    
    required init?(coder: NSCoder) {
        fatalError("init(coder:) has not been implemented")
    }
    
    deinit {
        NotificationCenter.default.removeObserver(self)
    }
    
    override func loadView() {
        super.loadView()
        
        self.view.backgroundColor = .systemBackground
        
        containerView = UIView(frame: CGRect(x: 0.0, y: 0.0, width: self.view.frame.width, height: 100.0))
        self.view.addSubview(containerView)
        
        infoLabel = UILabel(frame: CGRect(x: 0.0, y: 0.0, width: containerView.frame.width, height: 30.0))
        infoLabel.autoresizingMask = .flexibleWidth
        infoLabel.textAlignment = .center
        infoLabel.textColor = .label
        infoLabel.font = UIFont.systemFont(ofSize: 17)
        containerView.addSubview(infoLabel)
        
        passcodeTextField = PasscodeTextField(frame: CGRect(x: 10.0, y: 35.0, width: containerView.frame.width - 20.0, height: 30.0),
                                              passcodeLength: 4)
        passcodeTextField.autoresizingMask = .flexibleWidth
        passcodeTextField.addTarget(self, action: #selector(passcodeTextFieldAction(_:)), for: .editingDidEndOnExit)
        containerView.addSubview(passcodeTextField)
        
        failedLabel = UILabel(frame: CGRect(x: 0.0, y: 70.0, width: 0.0, height: 0.0))
        failedLabel.autoresizingMask = [.flexibleLeftMargin, .flexibleRightMargin]
        failedLabel.textAlignment = .center
        failedLabel.textColor = .white
        failedLabel.backgroundColor = .systemRed
        failedLabel.font = UIFont.systemFont(ofSize: 15)
        failedLabel.layer.cornerRadius = 15
        failedLabel.isHidden = true
        failedLabel.clipsToBounds = true
        containerView.addSubview(failedLabel)
    }
    
    override func viewDidLayoutSubviews() {
        super.viewDidLayoutSubviews()
        
        self.layoutContainerView()
    }
        
    func setFailedLabelText(_ text: String?) {
        failedLabel.isHidden = text == nil
        
        failedLabel.text = text
        failedLabel.sizeToFit()
        failedLabel.frame = CGRect(x: containerView.frame.width/2.0 - (failedLabel.frame.width + 30.0)/2.0,
                                   y: failedLabel.frame.origin.y,
                                   width: failedLabel.frame.width + 30.0,
                                   height: 30.0)
    }
    
    func animateFailure() {
        let animation = CABasicAnimation(keyPath: "position")
        animation.duration = 0.09
        animation.repeatCount = 2
        animation.isRemovedOnCompletion = true
        animation.autoreverses = true
        animation.fromValue = CGPoint(x: passcodeTextField.center.x - 10, y: passcodeTextField.center.y)
        animation.toValue = CGPoint(x: passcodeTextField.center.x + 10, y: passcodeTextField.center.y)
        passcodeTextField.layer.add(animation, forKey: "position")
    }
    
    func didEnterPasscode() {
        
    }
}


private extension PasscodeViewController {
    
    func layoutContainerView() {
        containerView.frame = CGRect(x: 0.0,
                                     y: self.view.safeAreaInsets.top + (self.view.frame.height - self.view.safeAreaInsets.top - self.keyboardFrame.height)/2.0 - self.containerView.frame.height/2.0,
                                     width: self.view.frame.width,
                                     height: containerView.frame.height)
    }
    
    // MARK: - Actions
    @objc func passcodeTextFieldAction(_ sender: Any?) {
        self.didEnterPasscode()
    }
        
    // MARK: - Keyboard Notifications
    @objc func keyboardNotification(_ notification:Notification) {
        if let userInfo = notification.userInfo {
            if let frameValue = userInfo[UIResponder.keyboardFrameEndUserInfoKey] as? NSValue {
                self.keyboardFrame = frameValue.cgRectValue
                self.layoutContainerView()
            }
        }
    }
}
