//
//  PasscodeKitRessourceBundle.swift
//  PasscodeKit
//
//  Created by Dominic Rodemer on 21.10.24.
//

import Foundation

extension Bundle {
    /// The resource bundle for the PasscodeKit framework.
    ///
    /// This property resolves the bundle using the framework's identifier (`net.domzilla.PasscodeKit`).
    /// If the framework bundle cannot be found — for example, when running in a test host or
    /// an unexpected packaging configuration — it falls back to `Bundle.main` to ensure
    /// resource lookups do not fail at runtime.
    ///
    /// All internal PasscodeKit components use this property to load localized strings and assets,
    /// keeping resource access centralized in a single location.
    public static var PasscodeKitRessourceBundle: Bundle = .init(identifier: "net.domzilla.PasscodeKit") ?? Bundle.main
}
