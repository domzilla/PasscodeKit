//
//  LockViewController.swift
//  PasscodeKit Test
//
//  Created by Dominic Rodemer on 22.10.24.
//

import UIKit

import PasscodeKit

class LockViewController: UIViewController {
    
    let passcode: Passcode
    
    init(passcode: Passcode) {
        self.passcode = passcode
        
        super.init(nibName: nil, bundle: nil)
    }
    
    required init?(coder: NSCoder) {
        fatalError("init(coder:) has not been implemented")
    }
    
    override func viewDidLoad() {
        super.viewDidLoad()
        
        self.view.backgroundColor = .systemBackground

        let label = UILabel(frame: self.view.bounds)
        label.autoresizingMask = [.flexibleWidth, .flexibleHeight]
        label.text = "Unlocked"
        label.font = UIFont.boldSystemFont(ofSize: 30.0)
        label.textColor = .systemGreen
        label.textAlignment = .center
        self.view.addSubview(label)
        
        passcode.lock(self)
    }
}
