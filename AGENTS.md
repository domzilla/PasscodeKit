# PasscodeKit - AGENTS.md

## Project Overview
PasscodeKit is a lightweight, easy-to-use in-app passcode framework for iOS. It provides complete passcode management (create, change, remove, authenticate) with biometric authentication support (Face ID, Touch ID, Optic ID), both at the app level and per-view-controller level.

## Tech Stack
- **Language**: Swift (with Objective-C umbrella header)
- **Type**: Xcode Framework
- **Target-Platforms**: iOS
- **Apple Frameworks Used**: UIKit, LocalAuthentication, CryptoKit, Foundation

## Guides (MANDATORY)
Read `~/Agents/Guides/xcode-project-guide.md` in full before planning or editing anything.

Read these in full before touching the matching code:
- Swift style (`.swift`): `~/Agents/Style/swift-swiftui-style-guide.md`
- Accessibility (UI code, XIBs, storyboards): `~/Agents/Guides/accessibility-guide.md`

## Framework Dependencies
This framework has **zero external dependencies** — it uses only Apple system frameworks.

## Localization (MANDATORY)
- The framework supports 14 languages (en, ar, de, es, fr, hi, it, ja, ko, nl, pt, ru, tr, zh_CN)

## Build Commands
```bash
# Build (iOS)
xcodebuild -project src/PasscodeKit.xcodeproj -scheme PasscodeKit \
  -destination 'generic/platform=iOS' \
  -configuration Debug build

# Clean
xcodebuild -project src/PasscodeKit.xcodeproj -scheme PasscodeKit clean
```

## Testing (MANDATORY)
No test targets exist in this project.

## Notes
- Storage uses `UserDefaults` with `net.domzilla.PasscodeKit.*` key namespace
- Passcode hashing uses SHA256 (with optional MD5 legacy support)
