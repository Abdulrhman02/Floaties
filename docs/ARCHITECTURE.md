# Architecture

Floaties is a small native macOS application implemented in one Swift source file. SwiftUI renders note and dashboard content; AppKit owns windows, menu-bar integration, and native text-field behavior.

## Component map

| Component | Responsibility |
| --- | --- |
| `AppDelegate` | Application lifecycle, menu-bar menu, sleep and power-off save hooks |
| `NotesManager` | Note collection, windows, dashboard, persistence, stacking, restore, and deletion |
| `StickyNote` | Observable and Codable note state |
| `NoteBlock` / `TodoItem` | Flat inline document blocks and to-do state |
| `NoteWindowController` | One `NSPanel` per note, frame capture, pinning, and collapsing |
| `StickyNoteView` | Header, content blocks, task actions, and resize affordance |
| `TodoTextField` | Native field-editor commands for arrows, modified Return, indentation, and deletion |
| `BlockTextField` | Native text-block splitting, merging, slash commands, and navigation |
| `BlockDropDelegate` | Reordering any block within the note |
| `DashboardView` | Notes and Recently Deleted overview |

## Startup flow

1. `AppDelegate` changes the app to accessory mode and creates the status item.
2. `NotesManager` loads `notes.json`, falling back to `notes.backup.json` if necessary.
3. Legacy notes without content blocks are migrated in memory. Grouped checklist items and multiline text are normalized into individual inline blocks.
4. A window is created for every non-deleted note.
5. The loaded state is saved again so migrations become durable.

## Editing and persistence flow

`StickyNote` publishes edits and calls its attached change closure. `NotesManager` debounces ordinary edits briefly, then encodes the complete note collection. Window move and resize delegate callbacks update the same model, so geometry follows the normal persistence path.

Floaties also flushes immediately when:

- The app resigns active status
- The application terminates
- macOS is about to sleep
- macOS is about to power off

## Window and Space behavior

Pinned notes use floating window level plus `canJoinAllSpaces`, `fullScreenAuxiliary`, and `stationary` collection behavior. Unpinned notes use normal level with managed Space behavior.

Window movement is restricted to `WindowDragHandle`. Resizing is implemented by `WindowResizeNSView`, which keeps the top edge fixed while clamping the new size to the supported range.

## Inline editor behavior

`StickyNoteView` derives transient `BlockSection` runs from adjacent block kinds. Textual blocks—text, heading, bulleted list, and quote—stay visually lightweight; checklist runs receive one labeled card and item count. This grouping is presentation-only: each to-do remains its own authoritative `NoteBlock`, so focus, indentation, conversion, persistence, and cross-section drag reordering continue to operate at block granularity. Textual blocks share a style-aware `BlockTextField`; each to-do block contains exactly one `TodoItem` rendered through `TodoTextField`.

Return in a text field either executes a supported slash conversion or splits the string at the UTF-16 cursor position. A leading slash in the focused text block reveals a compact light suggestion surface. Filtering is shared with Return handling, so Return selects the visibly highlighted first match. Ending field editing clears block focus, hides the chooser, and removes the contextual placeholder from empty blocks.

Return in a to-do splits the item at the UTF-16 cursor position; an empty item becomes text. Shift-Return inserts a text block after the item. Tab and Shift-Tab change the persisted `indentLevel`, constrained to four levels and requiring a preceding to-do before indentation. Both native fields intercept Up and Down to move focus across block types.

Reordering starts only from the always-faint six-dot grip, which increases contrast on row hover. `BlockDropDelegate` then moves the authoritative `blocks` array directly, leaving normal field selection gestures untouched.

## Deletion lifecycle

The close button is an archive action, not destruction:

1. The note window closes.
2. `isDeleted` becomes `true` and `deletedAt` is recorded.
3. The note remains in the persisted collection and appears in Recently Deleted.
4. Restore clears the deletion fields and recreates its window.
5. Only **Delete Forever** removes the model from the collection.

## Source organization

The app currently remains single-file because its model, UI, and controllers are compact and tightly related. If the source becomes difficult to navigate, split by responsibility without changing behavior and update this document and `build.sh` together.
