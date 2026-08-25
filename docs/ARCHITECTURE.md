# Architecture

Floaties is a small native macOS application implemented in one Swift source file. SwiftUI renders note and dashboard content; AppKit owns windows, menu-bar integration, and native text-field behavior.

## Component map

| Component | Responsibility |
| --- | --- |
| `AppDelegate` | Application lifecycle, menu-bar menu, sleep and power-off save hooks |
| `NotesManager` | Note collection, windows, dashboard, persistence, stacking, restore, and deletion |
| `StickyNote` | Observable and Codable note state |
| `NoteBlock` / `TodoItem` | Mixed content sections and checklist rows |
| `NoteWindowController` | One `NSPanel` per note, frame capture, pinning, and collapsing |
| `StickyNoteView` | Header, content blocks, task actions, and resize affordance |
| `TodoTextField` | Native field-editor commands for arrows, Return, and deletion |
| `TodoDropDelegate` | In-section checklist reordering |
| `DashboardView` | Notes and Recently Deleted overview |

## Startup flow

1. `AppDelegate` changes the app to accessory mode and creates the status item.
2. `NotesManager` loads `notes.json`, falling back to `notes.backup.json` if necessary.
3. Legacy notes without content blocks are migrated in memory.
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

## Deletion lifecycle

The close button is an archive action, not destruction:

1. The note window closes.
2. `isDeleted` becomes `true` and `deletedAt` is recorded.
3. The note remains in the persisted collection and appears in Recently Deleted.
4. Restore clears the deletion fields and recreates its window.
5. Only **Delete Forever** removes the model from the collection.

## Source organization

The app currently remains single-file because its model, UI, and controllers are compact and tightly related. If the source becomes difficult to navigate, split by responsibility without changing behavior and update this document and `build.sh` together.
