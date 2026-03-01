//
//  PasscodeKitRessourceBundle.swift
//  PasscodeKit
//
//  Created by Dominic Rodemer on 21.10.24.
//

import Foundation

/// An extension on `Bundle` that provides access to the PasscodeKit framework's resource bundle.
///
/// The resource bundle contains all assets shipped with PasscodeKit, including localized strings
/// for 14 supported languages (en, ar, de, es, fr, hi, it, ja, ko, nl, pt, ru, tr, zh_CN)
/// and image assets used throughout the framework's UI.
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
