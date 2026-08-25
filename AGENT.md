# Floaties agent guide

This is the canonical maintenance guide for coding agents working in this repository. Read it before changing code, metadata, build behavior, or documentation.

## Project boundaries

- Floaties is a native macOS menu-bar app built with AppKit and SwiftUI.
- Application source is in `Sources/main.swift`.
- `build.sh` is the canonical reproducible build.
- Generated `build/` output must not be committed.
- User notes live outside the repository in `~/Library/Application Support/Floaties/`.

## Product invariants

- A note may mix text and checklist blocks in any order.
- `blocks` is authoritative persisted content; legacy top-level content fields exist only for migration compatibility.
- Closing a note moves it to Recently Deleted. Only an explicit permanent-delete action destroys it.
- Pinned means floating across Desktops/Spaces. Unpinned means normal layering on the current Desktop.
- The dotted header grip moves a note; the bottom-right grip resizes it; dragging a checklist row reorders it.
- Note content, completion state, deletion state, color, pin state, collapse state, position, and size must survive relaunch.
- Arabic and English input must remain valid Unicode throughout editing and persistence.

## Data safety

- Never use the user's real notes as destructive test data.
- Do not print note text in command output, logs, screenshots, fixtures, or bug reports.
- Prefer schema checks, record counts, or normalized hashes when validating persistence.
- New Codable fields require safe defaults or a migration. Never make an existing save undecodable.
- Preserve atomic primary writes, the backup file, and lifecycle flushes unless replacing them with an equally safe design.

## Required workflow

1. Inspect `git status` and read the documentation relevant to the request.
2. Make a focused change and preserve unrelated work.
3. Update documentation in the same commit using the matrix below.
4. Run:

   ```sh
   ./build.sh
   plutil -lint Info.plist
   codesign --verify --deep --strict build/Floaties.app
   git diff --check
   ```

5. Perform focused manual UI checks when behavior changes.
6. Summarize the behavior, documentation, validation, and any remaining risk.

## Documentation update matrix

| Change | Update |
| --- | --- |
| User-visible behavior or controls | `README.md` when headline-level, `docs/FEATURES.md`, `CHANGELOG.md` |
| App structure, lifecycle, windows, or Spaces | `docs/ARCHITECTURE.md`, `CHANGELOG.md` when user-visible |
| Codable fields, migrations, save, backup, or deletion | `docs/DATA_MODEL.md`, `docs/ARCHITECTURE.md`, `CHANGELOG.md` |
| Build commands, requirements, validation, or release steps | `docs/DEVELOPMENT.md`, `README.md` when onboarding changes |
| Agent workflow or project invariants | `AGENT.md`, `.codex/skills/floaties-maintainer/SKILL.md` |
| Any notable completed work | Add a concise item under **Unreleased** in `CHANGELOG.md` |

Do not update every document mechanically. Update each canonical description affected by the change and avoid duplicating detailed explanations across files.

## Source navigation

- Models: `TodoItem`, `NoteBlock`, and `StickyNote`
- Checklist editing: `TodoTextField`, `TodoRow`, and `TodoDropDelegate`
- Note UI: `StickyNoteView`
- AppKit windows: `StickyPanel` and `NoteWindowController`
- Dashboard: `DashboardNoteRow` and `DashboardView`
- Persistence and coordination: `NotesManager`
- Lifecycle and menu bar: `AppDelegate`

## Definition of done

A change is done only when the app builds, relevant behavior is checked, persistence compatibility is considered, required docs are current, and the working tree contains no generated or unrelated files.
