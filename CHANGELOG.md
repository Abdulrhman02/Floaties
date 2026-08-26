# Changelog

All notable changes to Floaties are recorded here.

## Unreleased

### Added

- Collapsible checklist sections with persisted expansion state.
- Draggable divider blocks available from `/divider` and the add-block menu.

### Changed

- Reduced inactive rendering and redundant disk work by ending editor focus on deactivation, extending the edit-save debounce, and ignoring unchanged window geometry.
- Simplified every new-note entry point to one immediate action that starts with an empty text block; checklist blocks remain available inside the editor.

### Removed

- Removed the ambiguous cascade/stack control from note headers and the menu bar; it rearranged windows but looked like a bulk-collapse action.

## 1.1.0 - 2026-08-26

### Added

- Keyboard and hover selection in the slash suggestion picker, with Up/Down wrapping and Return activation.
- Optional persisted note titles in the window header, visible while collapsed and preferred in dashboard summaries.
- Reproducible DMG and ZIP packaging with checksum output and optional Developer ID notarization.
- Heading, bulleted-list, and quote blocks in a compact, searchable slash suggestion picker.
- Functional slash block chooser, Notion-style to-do splitting and list exit, nested to-dos with Tab/Shift-Tab, non-interfering hover drag grips, and polished visual checklist sections.
- Notion-style continuous block editing with inline text and to-dos, text splitting, slash conversion, cross-block navigation, and whole-block reordering.
- Native macOS menu-bar sticky notes with floating and Space-aware pin behavior.
- Mixed free-text and checklist sections within the same note.
- Checklist keyboard controls, completion, deletion confirmation, and drag reordering.
- Note movement, resizing, collapsing, coloring, and cascading stacks.
- Dashboard with Notes, Recently Deleted, restoration, and permanent deletion.
- Atomic local persistence with backup recovery and legacy-schema migration.
- Arabic and English Unicode input support.
- Maintainer documentation, agent instructions, and the `floaties-maintainer` project skill.

### Fixed

- Unified all seven header controls with consistent circular styling and clearer stack, dashboard, and new-note symbols.
- Reworked collapse/expand into one constrained AppKit frame animation to remove snapping and layout jitter.
- Block reorder grips now stay hidden until their row is hovered, keeping the note visually quiet without shifting content.
- Empty block hints now appear only on the focused line, and the slash picker uses a stable light suggestion surface in either macOS appearance.
- Corrected light-note contrast for header menus, the bottom add control, and empty text/to-do placeholders.
