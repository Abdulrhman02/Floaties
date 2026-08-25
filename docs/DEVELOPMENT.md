# Development guide

## Prerequisites

- macOS 13 or newer
- Apple Swift toolchain with `swiftc`
- AppKit, SwiftUI, and UniformTypeIdentifiers frameworks from the macOS SDK

No third-party runtime dependencies are required.

## Build

```sh
./build.sh
```

The script creates and ad-hoc signs `build/Floaties.app`. Generated builds are ignored by Git.

## Validate

Run the complete local validation set after code or metadata changes:

```sh
./build.sh
plutil -lint Info.plist
codesign --verify --deep --strict build/Floaties.app
git diff --check
```

Then launch the build and perform focused manual checks proportional to the change:

```sh
open build/Floaties.app
```

## Manual smoke test

For a broad behavior change, verify:

1. Create a note and add both text and checklist sections.
2. Edit text, add tasks, use arrow navigation, check a task, and reorder a row.
3. Move and resize the window, then relaunch and confirm geometry persists.
4. Pin the note and switch Desktops; unpin it and confirm it stays on one Desktop.
5. Close the note, restore it from Recently Deleted, and confirm its content remains.
6. Confirm the dashboard counts Notes and Recently Deleted correctly.

Do not use real user note content as test fixtures. Persistence tests should compare counts or hashes without printing content.

## Change workflow

1. Read `AGENT.md` and the documentation relevant to the change.
2. Inspect the working tree before editing.
3. Implement the smallest coherent behavior change.
4. Update the required documentation using the matrix in `AGENT.md`.
5. Run the validation commands above.
6. Keep generated `build/` output out of commits.

## Versioning and releases

Application versions live in `Info.plist`:

- `CFBundleShortVersionString` is the user-visible version.
- `CFBundleVersion` is the monotonically increasing build number.

Before a release, update those values, move relevant entries from **Unreleased** in `CHANGELOG.md` into a dated version section, rebuild, and verify the packaged application.
