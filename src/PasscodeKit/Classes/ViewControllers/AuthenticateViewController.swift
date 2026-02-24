//
//  AuthenticateViewController.swift
//  PasscodeKit
//
//  Created by Dominic Rodemer on 30.04.25.
//

import UIKit

internal class AuthenticateViewController: PasscodeViewController {
    
    let authenticationHandler: AuthenticationHandler

    init(passcode: Passcode, authenticationHandler: @escaping AuthenticationHandler) {
        self.authenticationHandler = authenticationHandler
        
        super.init(passcode: passcode)
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
        
        self.passcodeTextField.returnKeyType = .done
        self.passcodeTextField.reloadInputViews()
        
        self.navigationItem.rightBarButtonItem = UIBarButtonItem(barButtonSystemItem: .cancel,
                                                                 target: self,
                                                                 action: #selector(cancelButtonAction(_:)))
    }
    
    override func viewWillAppear(_ animated: Bool) {
        super.viewWillAppear(animated)
        
        if !Passcode.isBiometricsEnabled() {
            self.passcodeTextField.becomeFirstResponder()
        }
    }
    
    override func viewDidAppear(_ animated: Bool) {
        super.viewDidAppear(animated)
        
        if Passcode.isBiometricsEnabled() && !(self.passcode is AppPasscode) {
            Task {
                var authenticated = false
                do {
                    authenticated = try await self.passcode.authenticate(nil)
                } catch {
                    debugPrint(error)
                }
            
                if !authenticated {
                    self.passcodeTextField.becomeFirstResponder()
                } else {
                    self.authenticationHandler(true)
                    self.dismiss(animated: true)
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
                self.authenticationHandler(true)
                self.dismiss(animated: true)
            }
        }
    }
}


private extension AuthenticateViewController {
        
    // MARK: - Actions
    @objc func cancelButtonAction(_ sender: Any?) {
        self.authenticationHandler(false)
        self.dismiss(animated: true)
    }
}
