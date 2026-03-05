# PasscodeKit - AGENTS.md

## Project Overview
PasscodeKit is a lightweight, easy-to-use in-app passcode framework for iOS. It provides complete passcode management (create, change, remove, authenticate) with biometric authentication support (Face ID, Touch ID, Optic ID), both at the app level and per-view-controller level.

## Tech Stack
- **Language**: Swift 5 (with Objective-C umbrella header)
- **Type**: Xcode Framework
- **Target-Platforms**: iOS 17.0+
- **Apple Frameworks Used**: UIKit, LocalAuthentication, CryptoKit, Foundation

## Framework Dependencies
This framework has **zero external dependencies** — it uses only Apple system frameworks.

## Style & Conventions (MANDATORY)
Style guides are loaded automatically via `~/.claude/rules/` based on file type.
- **Swift** (`*.swift`): `~/Agents/Style/swift-swiftui-style-guide.md`

## Changelog (MANDATORY)
**All important code changes** (fixes, additions, deletions, changes) have to written to CHANGELOG.md.
Changelog format is based on [Keep a Changelog](https://keepachangelog.com/en/1.1.0/),
and this project adheres to [Semantic Versioning](https://semver.org/spec/v2.0.0.html).

**Before writing to CHANGELOG.md:**
1. Check for new release tags: `git tag --sort=-creatordate | head -1`
2. Release tags are prefixed with `v` (e.g., `v2.0.1`)
3. If a new tag exists that isn't in CHANGELOG.md, create a new version section with that tag's version and date, moving relevant [Unreleased] content under it

## Localization (MANDATORY)
**Strictly follow** the localization guide: `~/Agents/Guides/localization-guide.md`
- All user-facing strings must be localized
- The framework supports 14 languages (en, ar, de, es, fr, hi, it, ja, ko, nl, pt, ru, tr, zh_CN)
- Follow formality rules per language
- Consistency is paramount

## Logging (MANDATORY)

### Swift (DZFoundation)
```swift
import DZFoundation

DZLog("Starting fetch")       // General debug output
DZErrorLog(error)             // Conditional error logging (only prints if error is non-nil)
```

**Do NOT use:**
- `print()` / `NSLog()` for debug output
- `os.Logger` instances

All logging functions are no-ops in release builds.

## API Documentation
Local Apple API documentation is available at:
`~/Agents/API Documentation/Apple/`

```bash
~/Agents/API\ Documentation/Apple/search --help  # Run once per session
~/Agents/API\ Documentation/Apple/search "LAContext" --language swift
~/Agents/API\ Documentation/Apple/search "CryptoKit" --language swift
```

## Xcode Project Files (CATASTROPHIC — DO NOT TOUCH)
- **NEVER edit Xcode project files** (`.xcodeproj`, `.xcworkspace`, `project.pbxproj`, `.xcsettings`, etc.)
- Editing these files will corrupt the project — this is **catastrophic and unrecoverable**
- Only the user edits project settings, build phases, schemes, and file references manually in Xcode
- If a file needs to be added to the project, **stop and tell the user** — do not attempt it yourself
- Use `xcodebuild` for building/testing only — never for project manipulation
- **Exception**: Only proceed if the user gives explicit permission for a specific edit

## File System Synchronized Groups (Xcode 16+)
This project uses **File System Synchronized Groups** (internally `PBXFileSystemSynchronizedRootGroup`), introduced in Xcode 16. This means:
- The `Classes/` and `Resources/` directories are **directly synchronized** with the file system
- **You CAN freely create, move, rename, and delete files** in these directories
- Xcode automatically picks up all changes — no project file updates needed
- This is different from legacy Xcode groups, which required manual project file edits

**Bottom line:** Modify source files in `Classes/` and `Resources/` freely. Just never touch the `.xcodeproj` files themselves.

## Build Commands
```bash
# Build (iOS)
xcodebuild -project src/PasscodeKit.xcodeproj -scheme PasscodeKit \
  -destination 'generic/platform=iOS' \
  -configuration Debug build

# Clean
xcodebuild -project src/PasscodeKit.xcodeproj -scheme PasscodeKit clean
```

No test targets exist in this project.

## Code Formatting — Swift Only (MANDATORY)
**Always run SwiftFormat after modifying Swift files:**
```bash
swiftformat .
```

SwiftFormat configuration is defined in `.swiftformat` at the project root. This enforces:
- 4-space indentation
- Explicit `self.` usage
- K&R brace style (Swift only — Objective-C uses Allman style per the ObjC style guide)
- Trailing commas in collections
- Consistent wrapping rules

**Do not commit unformatted Swift code.**

Objective-C files are not auto-formatted — follow the ObjC style guide manually.

---

## Notes
- All public APIs must have documentation comments
- Storage uses `UserDefaults` with `net.domzilla.PasscodeKit.*` key namespace
- Passcode hashing uses SHA256 (with optional MD5 legacy support)
