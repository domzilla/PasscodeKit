//
//  ViewController.swift
//  PasscodeKit Test
//
//  Created by Dominic Rodemer on 22.10.24.
//

import UIKit

import PasscodeKit

class ViewController: UIViewController {
    
    @IBOutlet var appPasscodeSwitch: UISwitch!
    @IBOutlet var appPasscodeChangeButton: UIButton!
    @IBOutlet var lockAppButton: UIButton!
    
    @IBOutlet var vcPasscodeSwitch: UISwitch!
    @IBOutlet var vcPasscodeChangeButton: UIButton!
    
    @IBOutlet var biometricSwitch: UISwitch!
    
    let vcPasscode = Passcode(key: "MyVC.Key")
    
    override func viewDidLoad() {
        super.viewDidLoad()
        
        self.updateUI()
        
        NotificationCenter.default.addObserver(self, selector: #selector(passcodeNotification(notification:)), name: Passcode.PasscodeCreatedNotification, object: nil)
        NotificationCenter.default.addObserver(self, selector: #selector(passcodeNotification(notification:)), name: Passcode.PasscodeChangedNotification, object: nil)
        NotificationCenter.default.addObserver(self, selector: #selector(passcodeNotification(notification:)), name: Passcode.PasscodeRemovedNotification, object: nil)
        NotificationCenter.default.addObserver(self, selector: #selector(passcodeNotification(notification:)), name: Passcode.PasscodeAuthenticatedNotification, object: nil)
    }

    @IBAction func appPasscodeSwitchAction(_ sender: Any?) {
        if AppPasscode.shared.isPasscodeSet() {
            AppPasscode.shared.remove(presentOn: self, animated: true)
        } else {
            AppPasscode.shared.create(presentOn: self, animated: true)
        }
        
        self.updateUI()
    }
    
    @IBAction func appPasscodeChangeButtonAction(_ sender: Any?) {
        AppPasscode.shared.change(presentOn: self, animated: true)
    }
    
    @IBAction func lockAppButtonAction(_ sender: Any?) {
        AppPasscode.shared.lock()
    }
    
    @IBAction func vcPasscodeSwitchAction(_ sender: Any?) {
        if vcPasscode.isPasscodeSet() {
            vcPasscode.remove(presentOn: self, animated: true)
        } else {
            vcPasscode.create(presentOn: self, animated: true)
        }
        
        self.updateUI()
    }
    
    @IBAction func vcPasscodeChangeButtonAction(_ sender: Any?) {
        vcPasscode.change(presentOn: self, animated: true)
    }
        
    @IBAction func vcShowButtonAction(_ sender: Any?) {
        let lockViewController = LockViewController(passcode: vcPasscode)
        self.present(lockViewController, animated: true)
    }
    
    @IBAction func biometricSwitchAction(_ sender: Any?) {
        Task {
            var enabled = false
            do {
                enabled = try await Passcode.enableBiometrics(biometricSwitch.isOn)
            } catch {
                debugPrint(error)
            }
        
            biometricSwitch.setOn(enabled, animated: true)
        }
    }
    
    func updateUI() {
        appPasscodeSwitch.setOn(AppPasscode.shared.isPasscodeSet(), animated: false)
        appPasscodeChangeButton.isEnabled = AppPasscode.shared.isPasscodeSet()
        lockAppButton.isEnabled = AppPasscode.shared.isPasscodeSet()
        
        vcPasscodeSwitch.setOn(vcPasscode.isPasscodeSet(), animated: false)
        vcPasscodeChangeButton.isEnabled = vcPasscode.isPasscodeSet()
        
        biometricSwitch.isEnabled = Passcode.canEnableBiometrics()
        biometricSwitch.setOn(biometricSwitch.isEnabled && Passcode.isBiometricsEnabled(), animated: false)
    }
    
    @objc func passcodeNotification(notification: NSNotification) {
        self.updateUI()
    }
}

