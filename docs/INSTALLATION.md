# Installation and platform support

## macOS

Download `Floaties-1.1.0-macOS.dmg` from the GitHub release, open it, and drag **Floaties** into **Applications**. The ZIP contains the same application bundle for users who prefer a direct archive.

The current public artifact is ad-hoc signed because this project does not have a Developer ID Application identity and notarization profile available. macOS may therefore block the first launch. To approve it without disabling Gatekeeper globally:

1. Move Floaties to Applications.
2. Control-click Floaties and choose **Open**.
3. Confirm **Open** in the macOS dialog.

Future maintainers can produce a Developer ID-signed, notarized artifact by setting `FLOATIES_SIGN_IDENTITY` and `FLOATIES_NOTARY_PROFILE` before running `./package-macos.sh`.

## Windows

There is no Windows installer in this release. Floaties currently imports AppKit and SwiftUI and uses `NSPanel`, macOS Spaces, AppKit field-editor commands, and macOS application-support paths. Those APIs cannot be packaged into a working Windows executable.

A real Windows release requires a platform port, not a packaging conversion. The port must provide equivalents for:

- Always-on-top and normal-layer windows
- Virtual-desktop behavior
- Mixed text and checklist block editing
- Keyboard command routing and drag reordering
- JSON persistence and migration compatibility
- Dashboard, Recently Deleted, stacking, collapse, and resize behavior
- MSIX or signed installer generation on a Windows build runner

Publishing a renamed or empty `.exe` would be misleading, so release automation must not attach a Windows artifact until that port passes parity and persistence tests.

## Building the macOS artifacts

```sh
./package-macos.sh
```

The generated DMG, ZIP, and `SHA256SUMS.txt` are written to `dist/` and intentionally excluded from Git.
