//
//  LockViewController.swift
//  PasscodeKit Test
//
//  Created by Dominic Rodemer on 22.10.24.
//

import PasscodeKit
import UIKit

class LockViewController: UIViewController {
    let passcode: Passcode

    init(passcode: Passcode) {
        self.passcode = passcode

        super.init(nibName: nil, bundle: nil)
    }

    @available(*, unavailable)
    required init?(coder _: NSCoder) {
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

        self.passcode.lock(self)
    }
}
