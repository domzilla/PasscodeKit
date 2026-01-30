# Changelog

All notable changes to this project will be documented in this file.

The format is based on [Keep a Changelog](https://keepachangelog.com/en/1.1.0/).

## [Unreleased]

## [November 2025]
### Changed
- Set deployment target back to iOS 15
- Raised deployment target

## [July 2025]
### Fixed
- Fixed issue that app wasn't locked after launch

## [June 2025]
### Changed
- Updated project

## [April 2025]
### Added
- Added modal authentication
### Changed
- Refactoring
- Updated project

## [February 2025]
### Added
- Added localizations
### Fixed
- Fixed typo

## [December 2024]
### Added
- Added MD5 legacy hashing support
### Changed
- Authenticate immediately if not locked

## [November 2024]
### Added
- Added method to present errors to user
- Added biometry information
- Added passcode options (4-digit, 6-digit, alphanumeric)
- Added app passcode feature with keychain integration
### Changed
- Throw biometric error for better error handling
- Automatically unlock app via FaceID after launch
- Automatically lock app when AppPasscode is set
- Major rewrite: Reuse VC code, make use of keychain
- Make create, change & remove methods public
- Refactoring and code formatting
### Fixed
- Fixed dynamic color
### Removed
- Removed keychain dependency

## [October 2024]
### Changed
- Updated README

## [December 2023]
### Changed
- Updated README

## [October 2023]
### Changed
- Updated README
- Updated PasscodeKit.podspec
- Version 1.0.4

## [September 2023]
### Added
- Created Package.swift for Swift Package Manager support
### Changed
- Version 1.0.3
- Version 1.0.2

## [August 2023]
### Changed
- Updated README

## [April 2023]
### Changed
- Updated README

## [May 2021]
### Changed
- Updated README
- General changes

## [April 2021]
### Added
- Initial release (1.0.0)
- Version 1.0.1
