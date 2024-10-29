//
//  ChangePasscodeViewController.swift
//  PasscodeKit
//
//  Created by Dominic Rodemer on 21.10.24.
//

import UIKit

private enum ChangePasscodeViewControllerState {
    case enterOldPasscode
    case enterNewPasscode
    case verifyNewPasscode
}

internal class ChangePasscodeViewController: PasscodeViewController {
    
    private var state: ChangePasscodeViewControllerState = .enterOldPasscode
    private var code: String?
    private var mismatch = false
    
    override init(passcode: Passcode) {
        super .init(passcode: passcode)
        
        self.title = NSLocalizedString("Change Passcode",
                                       bundle: Bundle.PasscodeKitRessourceBundle,
                                       comment: "Headline for 'Change Passcode' view")
    }
    
    required init?(coder: NSCoder) {
        fatalError("init(coder:) has not been implemented")
    }
    
    override func viewDidLoad() {
        super.viewDidLoad()

        self.navigationItem.rightBarButtonItem = UIBarButtonItem(barButtonSystemItem: .cancel,
                                                                 target: self,
                                                                 action: #selector(cancelButtonAction(_:)))
        
        self.updateUI()
    }
    
    override func viewWillAppear(_ animated: Bool) {
        super.viewWillAppear(animated)
        
        self.passcodeTextField.becomeFirstResponder()
    }
    
    override func didEnterPasscode() {
        super.didEnterPasscode()
        
        if self.state == .enterOldPasscode {
            Task {
                var authenticated = false
                do {
                    authenticated = try await self.passcode.authenticate(self.passcodeTextField.text)
                } catch {
                    debugPrint(error)
                }
                
                self.mismatch = !authenticated
                self.passcodeTextField.clear()
                if !self.mismatch {
                    self.state = .enterNewPasscode
                    self.animatePasscodeTextField()
                } else {
                    self.animateFailure()
                }
                
                self.updateUI()
            }
        } else if state == .enterNewPasscode {
            self.code = self.passcodeTextField.text
            self.passcodeTextField.clear()
            self.mismatch = false
            self.animatePasscodeTextField()
            self.state = .verifyNewPasscode
            self.updateUI()
        } else if state == .verifyNewPasscode {
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
            }
        }
    }
}


private extension ChangePasscodeViewController {
    
    func updateUI() {
        
        if self.state == .enterOldPasscode {
            self.infoLabel.text = NSLocalizedString("Enter your passcode",
                                                    bundle: Bundle.PasscodeKitRessourceBundle,
                                                    comment: "Promt user to enter passcode")
        } else if state == .enterNewPasscode {
            self.infoLabel.text = NSLocalizedString("Enter new passcode",
                                                    bundle: Bundle.PasscodeKitRessourceBundle,
                                                    comment: "Promt user to enter new passcode")
        } else if state == .verifyNewPasscode {
            self.infoLabel.text = NSLocalizedString("Verify new passcode",
                                                    bundle: Bundle.PasscodeKitRessourceBundle,
                                                    comment: "Promt user to verify new passcode")
        }
        
        if self.mismatch {
            self.setFailedLabelText(NSLocalizedString("Passcodes don't match. Try again.",
                                                      bundle: Bundle.PasscodeKitRessourceBundle,
                                                      comment: "Notify user that passcodes do not match"))
        } else {
            self.setFailedLabelText(nil);
        }
    }
    
    func animatePasscodeTextField() {
        let x = self.passcodeTextField.frame.origin.x
        self.passcodeTextField.frame.origin.x = x + (self.mismatch ? -250.0 : 250.0)
        UIView.animate(withDuration: 0.15) {
            self.passcodeTextField.frame.origin.x = x
        }
    }
    
    // MARK: - Actions
    @objc func cancelButtonAction(_ sender: Any?) {
        self.dismiss(animated: true)
    }
}
