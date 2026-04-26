# Changelog

All notable changes to this project will be documented in this file.

The format is based on [Keep a Changelog](https://keepachangelog.com/en/1.1.0/).

## [Unreleased]
### Added
- Documentation across the framework.

## [November 2025]
### Changed
- Set deployment target back to iOS 15.

## [July 2025]
### Fixed
- App was not locked after launch in some cases.

## [June 2025]
### Changed
- Updated project.

## [April 2025]
### Added
- Modal authentication.

## [February 2025]
### Added
- Localizations.

## [December 2024]
### Added
- MD5 legacy hash support for migrating older passcodes.

### Changed
- Authenticate immediately when the app is not locked.

## [November 2024]
### Added
- App passcode feature with keychain integration.
- Passcode options for 4-digit, 6-digit, and alphanumeric codes.
- Method to present authentication errors to the user.
- Biometry information helpers.

### Changed
- Major rewrite that reuses view controller code and uses the keychain for storage.
- Auto-unlock via Face ID after launch and auto-lock when an app passcode is set.
- `create`, `change`, and `remove` methods are now public.

### Fixed
- Dynamic color handling.

### Removed
- External keychain dependency.

## [October 2024]
### Changed
- Updated README.

## [December 2023]
### Changed
- Updated README.

## [October 2023]
### Changed
- Updated README and podspec (1.0.4).

## [September 2023]
### Added
- `Package.swift` for Swift Package Manager support.

## [August 2023]
### Changed
- Updated README.

## [April 2023]
### Changed
- Updated README.

## [May 2021]
### Changed
- Updated README.

## [April 2021]
### Added
- Initial release (1.0.0).
