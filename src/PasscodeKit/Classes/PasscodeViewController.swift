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
    
    var optionButton: UIButton!
    
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
        
        containerView = UIView(frame: CGRect(x: 0.0, y: 0.0, width: self.view.frame.width, height: 120.0))
        self.view.addSubview(containerView)
        
        infoLabel = UILabel(frame: CGRect(x: 0.0, y: 0.0, width: containerView.frame.width, height: 30.0))
        infoLabel.autoresizingMask = .flexibleWidth
        infoLabel.textAlignment = .center
        infoLabel.textColor = .label
        infoLabel.font = UIFont.systemFont(ofSize: 17)
        containerView.addSubview(infoLabel)
        
        passcodeTextField = PasscodeTextField(frame: CGRect(x: containerView.frame.width/2.0 - 240.0/2.0, y: 35.0, width: 240.0, height: 50.0),
                                              passcodeOption: passcode.option)
        passcodeTextField.autoresizingMask = [.flexibleLeftMargin, .flexibleRightMargin]
        passcodeTextField.addTarget(self, action: #selector(passcodeTextFieldAction(_:)), for: .editingDidEndOnExit)
        passcodeTextField.delegate = self
        containerView.addSubview(passcodeTextField)
        
        failedLabel = UILabel(frame: CGRect(x: 0.0, y: 85.0, width: 0.0, height: 0.0))
        failedLabel.autoresizingMask = [.flexibleLeftMargin, .flexibleRightMargin]
        failedLabel.textAlignment = .center
        failedLabel.textColor = .white
        failedLabel.backgroundColor = .systemRed
        failedLabel.font = UIFont.systemFont(ofSize: 15)
        failedLabel.layer.cornerRadius = 15
        failedLabel.isHidden = true
        failedLabel.clipsToBounds = true
        containerView.addSubview(failedLabel)
        
        var optionButtonConfiguration = UIButton.Configuration.plain()
        optionButtonConfiguration.title = NSLocalizedString("Code options",
                                                            bundle: Bundle.PasscodeKitRessourceBundle,
                                                            comment: "Title for code options button")
        optionButton = UIButton(configuration: optionButtonConfiguration)
        optionButton.autoresizingMask = [.flexibleLeftMargin, .flexibleRightMargin]
        optionButton.changesSelectionAsPrimaryAction = false
        optionButton.showsMenuAsPrimaryAction = true
        optionButton.menu = UIMenu(children: [UIAction(title: NSLocalizedString("4-Digit Numeric Code",
                                                                                bundle: Bundle.PasscodeKitRessourceBundle,
                                                                                comment: "Code option: 4-digit numeric"),
                                                       handler: { action in self.passcodeTextField.passcodeOption = .fourDigits}),
                                              UIAction(title: NSLocalizedString("6-Digit Numeric Code",
                                                                                bundle: Bundle.PasscodeKitRessourceBundle,
                                                                                comment: "Code option: 6-digit numeric"), 
                                                       handler: { action in self.passcodeTextField.passcodeOption = .sixDigits}),
                                              UIAction(title: NSLocalizedString("Custom Alphanumeric Code",
                                                                                bundle: Bundle.PasscodeKitRessourceBundle,
                                                                                comment: "Code option: custom alphanumeric"), 
                                                       handler: { action in self.passcodeTextField.passcodeOption = .alphanumerical})])
        optionButton.sizeToFit()
        optionButton.frame = CGRect(x: containerView.frame.width/2.0 - optionButton.frame.width/2.0,
                                    y: 85.0,
                                    width: optionButton.frame.width,
                                    height: 30.0)
        optionButton.isHidden = true
        containerView.addSubview(optionButton)
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

extension PasscodeViewController: UITextFieldDelegate {
    
    func textFieldShouldReturn(_ textField: UITextField) -> Bool {
        self.didEnterPasscode()
        return false;
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
