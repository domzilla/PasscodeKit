//
//  Biometry.swift
//  PasscodeKit
//
//  Created by Dominic Rodemer on 04.11.24.
//

import LocalAuthentication
import UIKit

/// A singleton utility class that detects and exposes the device's biometric authentication capability.
///
/// `Biometry` queries the `LAContext` from the LocalAuthentication framework at initialization time
/// to determine whether the device supports Face ID, Touch ID, or Optic ID. It provides the detected
/// biometry type along with a human-readable name and a corresponding SF Symbol image name for use in UI.
///
/// - Important: Access this class exclusively through the ``shared`` singleton. Do not instantiate it directly.
@objc
public class Biometry: NSObject {
    /// The shared singleton instance of `Biometry`.
    ///
    /// This instance is created once and caches the detected biometric capability for the lifetime of the app.
    @objc public static let shared = Biometry()

    /// The biometry type available on the current device.
    ///
    /// Defaults to `.none` if no biometric hardware is available or if biometric evaluation cannot be performed.
    @objc public var type: LABiometryType = .none

    /// The human-readable display name for the detected biometry type.
    ///
    /// Returns `"Face ID"`, `"Touch ID"`, or `"Optic ID"` depending on the hardware. Returns `nil` if no
    /// biometric capability is available.
    @objc public var name: String?

    /// The SF Symbol name corresponding to the detected biometry type.
    ///
    /// Returns `"faceid"`, `"touchid"`, or `"opticid"` depending on the hardware. Returns `nil` if no
    /// biometric capability is available.
    @objc public var imageName: String?

    /// Initializes the biometry detector by querying the device for its biometric capability.
    ///
    /// Creates an `LAContext` and evaluates whether the device can perform biometric authentication.
    /// Based on the result, it populates ``type``, ``name``, and ``imageName`` with the appropriate values.
    ///
    /// - Note: This initializer is `internal` because consumers should use the ``shared`` singleton instead.
    override init() {
        super.init()

        let context = LAContext()
        var error: NSError?
        _ = context.canEvaluatePolicy(.deviceOwnerAuthenticationWithBiometrics, error: &error)
        if let error { debugPrint(error) }

        self.type = context.biometryType

        if self.type == .opticID {
            self.name = "Optic ID"
            self.imageName = "opticid"
        } else if self.type == .faceID {
            self.name = "Face ID"
            self.imageName = "faceid"
        } else if self.type == .touchID {
            self.name = "Touch ID"
            self.imageName = "touchid"
        }
    }

    /// Presents a localized error alert when biometric authentication is unavailable due to missing permissions.
    ///
    /// If the provided error is an `LAError` with code `.biometryNotAvailable`, this method presents a
    /// `UIAlertController` informing the user that the app lacks biometric access. The alert offers a
    /// "Cancel" action and a "Settings" action that deep-links to the app's system settings page so the
    /// user can grant the required permission.
    ///
    /// - Parameter viewController: The view controller on which to present the error alert.
    /// - Parameter error: The error returned from a biometric authentication attempt.
    /// - Parameter appName: The display name of the app, used in the alert message.
    ///
    /// - Note: If the error is not an `LAError` or has a code other than `.biometryNotAvailable`,
    ///   this method does nothing.
    @objc
    public static func presentErrorAlert(
        on viewController: UIViewController,
        with error: Error,
        appName: String
    ) {
        if let error = error as? LAError {
            if error.code == .biometryNotAvailable {
                let alertController = UIAlertController(
                    title: error.localizedDescription,
                    message: String(
                        format: NSLocalizedString(
                            "%@ doesn't have access to biometric authentication.",
                            bundle: Bundle.PasscodeKitRessourceBundle,
                            comment: "Message that the app doesn't have access rights to biometric authentication. Placeholder is app name."
                        ),
                        appName
                    ),
                    preferredStyle: .alert
                )
                alertController.addAction(UIAlertAction(
                    title: NSLocalizedString(
                        "Cancel",
                        bundle: Bundle
                            .PasscodeKitRessourceBundle,
                        comment: "Title for 'Cancel' Button"
                    ),
                    style: .cancel
                ))
                alertController.addAction(UIAlertAction(
                    title: NSLocalizedString(
                        "Settings",
                        bundle: Bundle
                            .PasscodeKitRessourceBundle,
                        comment: "Title for 'Settings' Button"
                    ),
                    style: .default,
                    handler: { _ in
                        UIApplication.shared.open(
                            URL(string: UIApplication.openSettingsURLString)!,
                            options: [:],
                            completionHandler: nil
                        )
                    }
                ))
                viewController.present(alertController, animated: true)
            }
        }
    }
}
