//
//  AuthenticateViewController.swift
//  PasscodeKit
//
//  Created by Dominic Rodemer on 21.10.24.
//

import UIKit

internal class AuthenticateViewController: PasscodeViewController {
        
    override init(passcode: Passcode) {
        super.init(passcode: passcode)
                
        NotificationCenter.default.addObserver(self,
                                               selector: #selector(passcodeAuthenticatedNotification(notification:)),
                                               name: Passcode.PasscodeAuthenticatedNotification,
                                               object: passcode)
    }
    
    required init?(coder: NSCoder) {
        fatalError("init(coder:) has not been implemented")
    }
    
    deinit {
        NotificationCenter.default.removeObserver(self)
    }
    
    override func viewDidLoad() {
        super.viewDidLoad()
        
        self.infoLabel.text = NSLocalizedString("Enter your passcode",
                                                bundle: Bundle.PasscodeKitRessourceBundle,
                                                comment: "Promt user to enter passcode")
    }
    
    override func viewWillAppear(_ animated: Bool) {
        super.viewWillAppear(animated)
        
        if !Passcode.isBiometricsEnabled() {
            self.passcodeTextField.becomeFirstResponder()
        }
    }
    
    override func viewDidAppear(_ animated: Bool) {
        super.viewDidAppear(animated)
        
        if Passcode.isBiometricsEnabled() {
            Task {
                var authenticated = false
                do {
                    authenticated = try await self.passcode.authenticate(nil)
                } catch {
                    debugPrint(error)
                }
            
                if !authenticated {
                    self.passcodeTextField.becomeFirstResponder()
                }
            }
        }
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
                self.setFailedLabelText(NSLocalizedString("Passcodes don't match. Try again.",
                                                          bundle: Bundle.PasscodeKitRessourceBundle,
                                                          comment: "Notify user that passcodes do not match"))
                self.animateFailure()
                self.passcodeTextField.clear()
            } else {
                self.setFailedLabelText(nil)
            }
        }
    }
}

private extension AuthenticateViewController {
    
    // MARK: - Passcode Notifications
    @objc func passcodeAuthenticatedNotification(notification: NSNotification) {
        if self.parent != nil {
            self.willMove(toParent: nil)
            self.view.removeFromSuperview()
            self.removeFromParent()
        }
    }
}
