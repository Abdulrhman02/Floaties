---
name: floaties-maintainer
description: Maintain the Floaties native macOS app when implementing or reviewing note UI, checklist behavior, window and Space semantics, persistence, migrations, dashboard behavior, builds, or project documentation. Use only within the Floaties repository.
---

# Floaties Maintainer

Read `AGENT.md` before acting. It contains the product invariants, data-safety rules, validation commands, source map, and documentation-update matrix.

## Work with the right context

- Read `docs/FEATURES.md` for user-visible interaction changes.
- Read `docs/ARCHITECTURE.md` for window, lifecycle, component, or Space changes.
- Read `docs/DATA_MODEL.md` before changing Codable state, persistence, migration, deletion, or recovery.
- Read `docs/DEVELOPMENT.md` for build, validation, or release work.

## Preserve non-obvious behavior

- Treat `blocks` as authoritative content and keep older saves decodable.
- Preserve the optional title independently from blocks, render it in the persistent header so it remains visible when collapsed, and prefer it in dashboard summaries when non-empty.
- Keep deletion recoverable until the user explicitly chooses permanent deletion.
- Keep real note content out of test output and fixtures.
- Preserve the flat Notion-style block model: text, one-item to-do, heading, bulleted-list, and quote blocks; persisted indentation; and a focus-bound slash chooser. Consecutive to-dos receive one visual checklist section without changing the persisted block structure.
- Preserve the gesture split: header grip moves the window, bottom-right grip resizes it, and each block reveals its six-dot reorder grip only on hover without intercepting text selection.
- Keep instructional placeholders contextual: empty unfocused blocks must remain visually empty.
- Route Up and Down through the filtered slash chooser while it is visible, and apply its highlighted result on Return; outside that state, keep cross-block arrow navigation.
- Keep pinned and unpinned Space behavior distinct.
- Keep all seven header actions visually consistent, including the menu-backed palette and new-note actions.
- Treat the current target as macOS-only. Do not publish a Windows artifact until a real platform port passes behavior and persistence parity checks.

## Finish the whole change

Implement the requested behavior, update each affected canonical document using the matrix in `AGENT.md`, add a concise Unreleased changelog entry, and run the repository validation commands. Do not commit generated `build/` output.
