# Features and controls

## Notes

Each Floaties window is an independent sticky note. Its content behaves as one continuous, Notion-style document made from inline blocks. Text and to-dos remain freely mixable, while consecutive to-dos receive a subtle checklist section for cleaner visual structure.

- A text block appears as a plain editable line.
- A to-do block uses the same line layout with a checkbox.
- Adjacent to-dos share a labeled checklist card with an item count and an **Add item** control; text breaks the card and resumes the document flow.
- Blocks can be mixed and reordered in any sequence.
- Hover a block and drag its six-dot grip to reorder it. The separate grip keeps clicking and dragging inside text available for selection.

Press `Return` in text to split the current block at the cursor. Type `/` at the start of an empty text block to open the block chooser, then select **Text** or **To-do**. The typed shortcuts `/todo`, `/to-do`, `/checklist`, and `/text` also work with `Return`. The small `+` menu at the bottom can append either type without a command.

Right-click a block to convert its type or delete it. Backspace at the beginning of a text block merges it into the previous text block; Backspace on an empty text block removes it.

## Checklist controls

- Click the circle to check or uncheck an item.
- Hover and drag the six-dot grip to reorder a to-do anywhere in the note.
- Press `↑` or `↓` while editing to focus the previous or next block, including text.
- Press `Return` to split a to-do at the cursor and continue in a new to-do.
- Press `Return` on an empty to-do to turn it into normal text and leave the checklist.
- Press `Shift-Return` from any to-do to insert a normal text block underneath it.
- Press `Tab` to indent a to-do beneath the previous to-do, up to four levels. Press `Shift-Tab` to outdent it.
- Backspace and Forward Delete remove characters normally. When an item is already empty, deletion opens a confirmation dialog.
- In a deletion dialog, `Return` confirms and `Escape` cancels.

## Window controls

The dotted grip in the header is the only region that moves the window. This prevents block reordering from accidentally moving the entire note.

| Control | Behavior |
| --- | --- |
| Pin | Keeps the note above apps and visible across macOS Desktops/Spaces |
| Unpin | Uses normal window layering and keeps the note on its current Desktop |
| Palette | Selects one of the soft, saturated note colors |
| Stack | Cascades all non-deleted notes near the top-right of the current screen |
| Dashboard | Opens the Notes and Recently Deleted overview |
| Plus | Creates a new note starting with text or a checklist |
| Chevron | Collapses or expands the note |
| Close | Moves the note to Recently Deleted |

Drag the diagonal grip at the bottom-right to resize a note. The supported size range is 280–520 points wide and 180–700 points tall. Position, size, and collapsed height persist between launches.

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

## Language support

Text fields use native macOS controls and store Unicode strings. Arabic and English can be entered in text and checklist sections; the persisted format does not impose a language restriction.
