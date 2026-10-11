---
id: '261011-0QRYY78'
title: AutoFill callout covers the passcode prompt
author: Dominic Rodemer
created_at: '2026-10-11T06:45:50.863536Z'
status: open
labels:
- bug
attachments:
- '1-passcode-autofill.jpg'
---


## What to build

When the Create Passcode screen appears, the system "AutoFill" callout pops up on top of the "Enter your passcode" prompt, hiding most of the text. The hidden passcode text field should opt out of AutoFill suggestions (e.g. appropriate textContentType) so the callout doesn't appear.

Found in PDF Pro on iPhone 17e Simulator, iOS 27: Settings → App Passcode (also via Face ID).

## Acceptance criteria

- [ ] No AutoFill callout over the prompt when creating, confirming or entering a passcode

## Blocked by

- None (can start immediately)
