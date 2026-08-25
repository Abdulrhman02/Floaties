# Changelog

All notable changes to Floaties are recorded here.

## Unreleased

### Added

- Optional persisted note titles fixed above the document and preferred in dashboard summaries.
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
