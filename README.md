# Floaties

Floaties is a lightweight native macOS sticky-note utility that lives in the menu bar. Notes can float above other apps, follow you across Desktops, mix free-text and checklist sections, and be restored after deletion.

## Features

- Native always-on-top macOS note windows
- Mixed free-text and checklist sections in one note
- Drag-to-reorder checklist tasks
- Keyboard navigation and task completion controls
- Pin across Desktops or unpin to the current Desktop
- Multiple colors, stacking, collapsing, and resizing
- Notes dashboard with Recently Deleted and restore
- Atomic local persistence with a backup save
- Unicode text support, including Arabic and English

## Requirements

- macOS 13 or newer
- Apple Swift toolchain (`swiftc`)

## Build and run

```sh
./build.sh
open build/Floaties.app
```

The app stores note data in:

```text
~/Library/Application Support/Floaties/
```

## Controls

- Drag the dotted header grip to move a note.
- Drag the bottom-right diagonal grip to resize it.
- Press and drag a checklist row to reorder it.
- Use **Text** and **Checklist** at the bottom to add mixed sections.
- Open the dashboard from a note, the menu-bar item, or `Command-D`.
