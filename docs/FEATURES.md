# Features and controls

## Notes

Each Floaties window is an independent sticky note. A note can contain any number of content sections in any order:

- Free-text section
- Checklist section
- Another free-text section
- Another checklist section

Use **Text** or **Checklist** at the bottom of a note to append a section. A section's `…` menu removes that section when the note contains more than one.

## Checklist controls

- Click the circle to check or uncheck an item.
- Press and drag a checklist row to reorder it within its section.
- Press `↑` or `↓` while editing to focus the previous or next item.
- Press `Return` with the cursor at the end of the text to create the next item.
- Press `Return` with the cursor before the end to check or uncheck the current item.
- Backspace and Forward Delete remove characters normally. When an item is already empty, deletion opens a confirmation dialog.
- In a deletion dialog, `Return` confirms and `Escape` cancels.

## Window controls

The dotted grip in the header is the only region that moves the window. This prevents task reordering from accidentally moving the entire note.

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

## Language support

Text fields use native macOS controls and store Unicode strings. Arabic and English can be entered in text and checklist sections; the persisted format does not impose a language restriction.
