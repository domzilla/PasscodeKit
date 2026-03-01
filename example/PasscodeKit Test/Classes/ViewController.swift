//
//  ViewController.swift
//  PasscodeKit Test
//
//  Created by Dominic Rodemer on 22.10.24.
//

import PasscodeKit
import UIKit

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

        NotificationCenter.default.addObserver(
            self,
            selector: #selector(self.passcodeNotification(notification:)),
            name: Passcode.PasscodeCreatedNotification,
            object: nil
        )
        NotificationCenter.default.addObserver(
            self,
            selector: #selector(self.passcodeNotification(notification:)),
            name: Passcode.PasscodeChangedNotification,
            object: nil
        )
        NotificationCenter.default.addObserver(
            self,
            selector: #selector(self.passcodeNotification(notification:)),
            name: Passcode.PasscodeRemovedNotification,
            object: nil
        )
        NotificationCenter.default.addObserver(
            self,
            selector: #selector(self.passcodeNotification(notification:)),
            name: Passcode.PasscodeAuthenticatedNotification,
            object: nil
        )
    }

    @IBAction
    func appPasscodeSwitchAction(_: Any?) {
        if AppPasscode.shared.isPasscodeSet() {
            AppPasscode.shared.remove(presentOn: self, animated: true)
        } else {
            AppPasscode.shared.create(presentOn: self, animated: true)
        }

        self.updateUI()
    }

    @IBAction
    func appPasscodeChangeButtonAction(_: Any?) {
        AppPasscode.shared.change(presentOn: self, animated: true)
    }

    @IBAction
    func lockAppButtonAction(_: Any?) {
        AppPasscode.shared.lock()
    }

    @IBAction
    func vcPasscodeSwitchAction(_: Any?) {
        if self.vcPasscode.isPasscodeSet() {
            self.vcPasscode.remove(presentOn: self, animated: true)
        } else {
            self.vcPasscode.create(presentOn: self, animated: true)
        }

        self.updateUI()
    }

    @IBAction
    func vcPasscodeChangeButtonAction(_: Any?) {
        self.vcPasscode.change(presentOn: self, animated: true)
    }

    @IBAction
    func vcShowButtonAction(_: Any?) {
        let lockViewController = LockViewController(passcode: vcPasscode)
        self.present(lockViewController, animated: true)
    }

    @IBAction
    func biometricSwitchAction(_: Any?) {
        Task {
            var enabled = false
            do {
                enabled = try await Passcode.enableBiometrics(self.biometricSwitch.isOn)
            } catch {
                debugPrint(error)
            }

            self.biometricSwitch.setOn(enabled, animated: true)
        }
    }

    func updateUI() {
        self.appPasscodeSwitch.setOn(AppPasscode.shared.isPasscodeSet(), animated: false)
        self.appPasscodeChangeButton.isEnabled = AppPasscode.shared.isPasscodeSet()
        self.lockAppButton.isEnabled = AppPasscode.shared.isPasscodeSet()

        self.vcPasscodeSwitch.setOn(self.vcPasscode.isPasscodeSet(), animated: false)
        self.vcPasscodeChangeButton.isEnabled = self.vcPasscode.isPasscodeSet()

        self.biometricSwitch.isEnabled = Passcode.canEnableBiometrics()
        self.biometricSwitch.setOn(self.biometricSwitch.isEnabled && Passcode.isBiometricsEnabled(), animated: false)
    }

    @objc
    func passcodeNotification(notification _: NSNotification) {
        self.updateUI()
    }
}
