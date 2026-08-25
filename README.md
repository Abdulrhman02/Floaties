# Floaties

Floaties is a lightweight native macOS sticky-note utility that lives in the menu bar. Notes can float above other apps, follow you across Desktops, mix free-text and checklist sections, and be restored after deletion.

## Quick start

```sh
./build.sh
open build/Floaties.app
```

## Features

- Native always-on-top macOS note windows
- Notion-style inline text and to-do blocks in one note
- Drag-to-reorder checklist tasks
- Keyboard navigation and task completion controls
- Pin across Desktops or unpin to the current Desktop
- Multiple colors, stacking, collapsing, and resizing
- Notes dashboard with Recently Deleted and restore
- Atomic local persistence with a backup save
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
- Press and drag a checklist row to reorder it.
- Press `Return` to split text into blocks, or type `/todo` and press `Return` to create a to-do.
- Open the dashboard from a note, the menu-bar item, or `Command-D`.

## Project layout

```text
Sources/main.swift   Native application source
Info.plist           macOS application metadata
build.sh             Reproducible local build
docs/                Maintained project documentation
.codex/skills/       Project-specific Codex workflows
```
