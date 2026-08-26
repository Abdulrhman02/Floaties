# Features and controls

## Notes

Each Floaties window is an independent sticky note. Its content behaves as one continuous, Notion-style document made from inline blocks. Text and to-dos remain freely mixable, while consecutive to-dos receive a subtle checklist section for cleaner visual structure.

Each note also has an optional title in its top bar. It stays visible when the note is collapsed; leaving it empty has no effect, and when present the dashboard uses it as the note name.

- A text block appears as a plain editable line.
- A to-do block uses the same line layout with a checkbox.
- Heading, bulleted-list, quote, and divider blocks provide structure without creating separate note sections.
- Adjacent to-dos share a labeled checklist card with an item count and an **Add item** control; text or a divider breaks the card and resumes the document flow.
- Blocks can be mixed and reordered in any sequence.
- Hover a block to reveal its six-dot grip, then drag the grip to reorder the block. The reserved gutter prevents layout movement, while the separate grip keeps text selection working normally.

Press `Return` in text to split the current block at the cursor. Type `/` at the start of a focused text block to open a compact suggestion picker for **Text**, **To-do**, **Heading**, **Bulleted list**, **Quote**, and **Divider**. Keep typing to filter it, use `↑` and `↓` to move the highlight, and press `Return` to apply the selected result. The highlight wraps at the first and last result and also follows the hovered row. The typed shortcuts `/text`, `/todo`, `/heading`, `/bullet`, `/quote`, and `/divider` work directly. Creating a divider also creates and focuses an empty text block beneath it. The small `+` menu at the bottom offers the same block types.

Empty lines have no repeated default label. The contextual placeholder appears only while its empty field is focused and disappears when focus moves elsewhere.

Right-click a block to convert its type or delete it. Backspace at the beginning of a text block merges it into the previous text block; Backspace on an empty text block removes it.

## Checklist controls

- Click the chevron in a checklist header to collapse or expand the whole checklist section. Its state persists across launches.
- Click the circle to check or uncheck an item.
- Hover a to-do and drag the revealed six-dot grip to reorder it anywhere in the note.
- Press `↑` or `↓` while editing to focus the previous or next block, including text.
- Press `Return` to split a to-do at the cursor and continue in a new to-do.
- Press `Return` on an empty to-do to turn it into normal text and leave the checklist.
- Press `Shift-Return` from any to-do to insert a normal text block underneath it.
- Press `Tab` to indent a to-do beneath the previous to-do, up to four levels. Press `Shift-Tab` to outdent it.
- Backspace and Forward Delete remove characters normally. When an item is already empty, deletion opens a confirmation dialog.
- In a deletion dialog, `Return` confirms and `Escape` cancels.

## Window controls

The dotted grip in the header is the only region that moves the window. This prevents block reordering from accidentally moving the entire note.

The optional title field shares the header with the controls. It uses the available center space and remains editable and visible in the collapsed bar.

| Control | Behavior |
| --- | --- |
| Pin | Keeps the note above apps and visible across macOS Desktops/Spaces |
| Unpin | Uses normal window layering and keeps the note on its current Desktop |
| Palette | Selects one of the soft, saturated note colors |
| Layered windows | Cascades all non-deleted notes into an offset stack near the top-right of the current screen |
| Four-panel grid | Opens the Notes and Recently Deleted dashboard |
| Document plus | Creates a new note starting with text or a checklist |
| Chevron | Collapses or expands the note |
| Close | Moves the note to Recently Deleted |

All seven actions use the same circular background, size, and foreground treatment. Hovering any action shows a plain-language explanation, including **Cascade all notes on this screen** for the layered-window control.

Drag the diagonal grip at the bottom-right to resize a note. The supported size range is 280–520 points wide and 180–700 points tall. Position, size, and collapsed height persist between launches. Collapse and expansion use one coordinated ease-in/ease-out frame animation while keeping the top edge anchored.

## Dashboard

The dashboard has two views:

- **Notes** contains every note that has not been explicitly deleted, whether or not it is currently frontmost.
- **Recently Deleted** contains closed notes and lets the user restore or permanently delete them.

Open the dashboard from a note, from the menu-bar item, or with `Command-D` while Floaties is active.

## Menu-bar commands

- New note starting with text
- New note starting with a checklist
- Open the dashboard
- Stack notes
- Show or hide all note windows
- Bring note windows forward
- Quit Floaties

Floaties uses `LSUIElement`, so it stays out of the Dock.

All controls and empty-field placeholders use dark or gray foregrounds across the current light note palette for consistent contrast.

## Resource behavior

Floaties has no network client or background polling loop. Ordinary edits use a short save debounce, while application deactivation, sleep, power-off, and termination still flush immediately. Leaving Floaties ends active text editing so an inactive insertion cursor does not keep its SwiftUI window repainting.

## Language support

Text fields use native macOS controls and store Unicode strings. Arabic and English can be entered in text and checklist sections; the persisted format does not impose a language restriction.
