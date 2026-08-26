# Floaties

Floaties is a lightweight native macOS sticky-note utility that lives in the menu bar. Notes can have optional always-visible header titles, float above other apps, follow you across Desktops, mix free-text and checklist sections, and be restored after deletion.

## Install

Download the DMG from the [latest GitHub release](https://github.com/Abdulrhman02/Floaties/releases/latest), open it, and drag Floaties into Applications. See [Installation and platform support](docs/INSTALLATION.md) for Gatekeeper instructions, the ZIP option, checksums, and Windows status.

## Quick start

```sh
./build.sh
open build/Floaties.app
```

## Features

- Native always-on-top macOS note windows
- Notion-style text, to-do, heading, bulleted-list, quote, and divider blocks in one note
- Collapsible checklist sections with persisted expansion state
- Compact slash suggestion picker and hover-only drag grips
- Keyboard navigation and task completion controls
- Pin across Desktops or unpin to the current Desktop
- Multiple colors, stacking, collapsing, and resizing
- Notes dashboard with Recently Deleted and restore
- Atomic local persistence with a backup save
- Native idle behavior with no network access or background polling
- Unicode text support, including Arabic and English

## Documentation

| Guide | Purpose |
| --- | --- |
| [Features](docs/FEATURES.md) | User-visible behavior and controls |
| [Architecture](docs/ARCHITECTURE.md) | Components, lifecycle, and window behavior |
| [Data model](docs/DATA_MODEL.md) | Persistence schema, migrations, and recovery |
| [Development](docs/DEVELOPMENT.md) | Build, validation, and contribution workflow |
| [Changelog](CHANGELOG.md) | Project history and unreleased changes |
| [Agent guide](AGENT.md) | Maintenance rules for coding agents |

The complete documentation index is in [docs/README.md](docs/README.md).

## Requirements

- macOS 13 or newer
- Apple Swift toolchain (`swiftc`)

The app stores note data in:

```text
~/Library/Application Support/Floaties/
```

## Controls

- Drag the dotted header grip to move a note.
- Drag the bottom-right diagonal grip to resize it.
- Drag a block's six-dot grip to reorder it.
- Type `/` for the block suggestion picker, use `↑`/`↓` to select a result, and press `Return` to apply it.
- Edit the optional title directly in the header; it remains visible when the note is collapsed.
- Open the dashboard from a note, the menu-bar item, or `Command-D`.

## Project layout

```text
Sources/main.swift   Native application source
Info.plist           macOS application metadata
build.sh             Reproducible local build
package-macos.sh     DMG and ZIP release packaging
docs/                Maintained project documentation
.codex/skills/       Project-specific Codex workflows
```
