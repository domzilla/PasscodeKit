---
id: '261006-0R7WQC2'
title: Change passcode UI posts Created instead of Changed notification
author: Dominic Rodemer
created_at: '2026-10-06T06:53:48.186430Z'
status: open
labels:
- bug
---

> **Note:** Agent-generated from an automated doc/code review. This may be a false positive — analyze and confirm against the code before fixing.

`ChangePasscodeViewController` saves the new code via `self.passcode.create(code)` instead of `change(_:)` (src/PasscodeKit/Classes/ViewControllers/ChangePasscodeViewController.swift:93).
Impact: `change(presentOn:animated:)` calls `passcodeCreated` on the delegate and posts `PasscodeCreatedNotification`; `passcodeChanged` / `PasscodeChangedNotification` never fire, contradicting the docs in Passcode.swift:259.
Fix: call `self.passcode.change(code)` there.
