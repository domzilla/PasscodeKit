# PasscodeKit

A lightweight, easy-to-use in-app passcode framework for iOS.

PasscodeKit provides a complete passcode experience — creation, verification, change, and removal — with built-in biometric authentication (Face ID, Touch ID, Optic ID). Use it to protect your entire app or individual view controllers.

## Features

- **Multiple passcode types** — 4-digit, 6-digit, or custom alphanumeric
- **Biometric authentication** — Face ID, Touch ID, and Optic ID support
- **App-level passcode** — Automatically locks/unlocks the app on background/foreground transitions
- **Per-view-controller passcode** — Lock individual screens independently
- **Secure storage** — SHA256 hashed passcodes (with optional MD5 legacy support)
- **Localized** — 14 languages out of the box (Arabic, Chinese, Dutch, English, French, German, Hindi, Italian, Japanese, Korean, Portuguese, Russian, Spanish, Turkish)
- **Zero dependencies** — Uses only Apple system frameworks (UIKit, LocalAuthentication, CryptoKit)
- **Objective-C compatible** — Full `@objc` interoperability

## Requirements

- iOS 15.0+
- Swift 5+
- Xcode 15+

## Installation

### Manual

1. Clone or download this repository
2. Drag `src/PasscodeKit.xcodeproj` into your Xcode project
3. Add `PasscodeKit.framework` to your target's **Frameworks, Libraries, and Embedded Content**

## Usage

### App-Level Passcode

Protect your entire app with a single call in your `AppDelegate`:

```swift
import PasscodeKit

func application(_ application: UIApplication, didFinishLaunchingWithOptions launchOptions: [UIApplication.LaunchOptionsKey: Any]?) -> Bool {
    AppPasscode.applicationDidFinishLaunching()
    return true
}
```

`AppPasscode` automatically locks the app when it enters the background and prompts for authentication when it returns to the foreground. If biometrics are enabled, it will attempt to unlock via Face ID / Touch ID automatically.

### Per-View-Controller Passcode

Create a `Passcode` instance with a unique key and use it to lock specific view controllers:

```swift
let passcode = Passcode(key: "myFeature")

// Lock a view controller (adds a lock overlay)
passcode.lock(self)

// Authenticate modally
passcode.authenticate(presentOn: self, animated: true) { success in
    if success {
        // Access granted
    }
}
```

### Creating, Changing, and Removing Passcodes

```swift
let passcode = Passcode(key: "myFeature")

// Present the creation flow
passcode.create(presentOn: self, animated: true)

// Present the change flow (verifies old passcode first)
passcode.change(presentOn: self, animated: true)

// Present the removal flow (verifies passcode before removing)
passcode.remove(presentOn: self, animated: true)

// Check if a passcode is set
if passcode.isPasscodeSet() {
    // ...
}
```

### Biometric Authentication

```swift
// Check if biometrics are available
if Passcode.canEnableBiometrics() {
    // Enable biometrics (prompts user for permission)
    Task {
        let enabled = try await Passcode.enableBiometrics(true)
    }
}

// Check current biometry type
let biometry = Biometry.shared
print(biometry.name)      // "Face ID", "Touch ID", or "Optic ID"
print(biometry.imageName)  // "faceid", "touchid", or "opticid"
```

### Notifications

PasscodeKit posts notifications for all passcode events:

```swift
Passcode.PasscodeCreatedNotification
Passcode.PasscodeChangedNotification
Passcode.PasscodeRemovedNotification
Passcode.PasscodeAuthenticatedNotification
Passcode.PasscodeAuthenticationFaliureNotification
```

### Delegate

Alternatively, conform to `PasscodeDelegate` for callback-based observation:

```swift
passcode.delegate = self

func passcodeCreated(_ passcode: Passcode) { }
func passcodeChanged(_ passcode: Passcode) { }
func passcodeRemoved(_ passcode: Passcode) { }
func passcodeAuthenticated(_ passcode: Passcode) { }
func passcodeAuthenticationFaliure(_ passcode: Passcode) { }
```

## Example Project

An example iOS app is included in the `example/` directory demonstrating both app-level and per-view-controller passcode usage.

## License

PasscodeKit is available under the MIT license. See the [LICENSE](LICENSE) file for details.
