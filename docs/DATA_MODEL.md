# Data model and persistence

## Storage location

Floaties keeps user data locally in:

```text
~/Library/Application Support/Floaties/notes.json
~/Library/Application Support/Floaties/notes.backup.json
```

The app does not send note content over the network.

## Persisted model

The root value is an array of notes. The following abbreviated example uses invented content:

```json
[
  {
    "id": "00000000-0000-0000-0000-000000000000",
    "blocks": [
      {
        "id": "11111111-1111-1111-1111-111111111111",
        "kind": "text",
        "text": "Release notes",
        "todos": [],
        "indentLevel": 0
      },
      {
        "id": "22222222-2222-2222-2222-222222222222",
        "kind": "checklist",
        "text": "",
        "indentLevel": 1,
        "todos": [
          {
            "id": "33333333-3333-3333-3333-333333333333",
            "text": "Build app",
            "isDone": false
          }
        ]
      }
    ],
    "colorHex": "FFD45A",
    "isPinned": true,
    "isCollapsed": false,
    "isDeleted": false,
    "x": 900,
    "y": 450,
    "width": 320,
    "height": 300,
    "expandedHeight": 300
  }
]
```

`deletedAt` is present only for deleted notes.

## Authoritative fields

- `blocks` is the authoritative note content.
- Textual blocks use their `text` field. Supported persisted kinds are `"text"`, `"heading"`, `"bullet"`, and `"quote"`.
- A to-do block uses `kind: "checklist"` and contains exactly one entry in its `todos` array. The persisted case name remains `checklist` for compatibility.
- `indentLevel` stores checklist nesting from `0` through `4`. Missing, negative, or oversized values decode safely and are clamped into that range.
- Todo identifiers are globally unique within the app, which allows focus and delete actions to locate an item across blocks.
- `x`, `y`, `width`, `height`, and `expandedHeight` preserve window geometry.

The top-level `text`, `todos`, and `isChecklist` fields remain encoded for compatibility with earlier builds. New behavior must read and write `blocks`; do not make the legacy fields authoritative again.

## Compatibility rules

Decoding supplies defaults for fields added after the first version. If `blocks` is absent, Floaties creates one block from the legacy content:

- `isChecklist == true` becomes one checklist block using `todos`.
- Otherwise, it becomes one text block using `text`.

After decoding, `NoteBlock.normalized` converts older grouped content into the flat editor model:

- A checklist block containing multiple items becomes one checklist block per item.
- A multiline textual block becomes one block of the same kind per line.
- Identifiers and content are preserved where possible; an empty document receives one empty text block.
- Older blocks without `indentLevel` decode at level `0`; normalization preserves indentation when it expands older grouped or multiline blocks.

When adding a persisted field:

1. Decode it with a safe default or an explicit migration.
2. Preserve all existing notes, blocks, todo completion states, deletion state, and geometry.
3. Save the migrated schema after load.
4. Update this document and `CHANGELOG.md` in the same change.

## Save and recovery strategy

Before an atomic primary write, the previous primary file is copied to `notes.backup.json`. Loading tries the primary file first and the backup second. A valid primary file seeds the backup if one does not exist.

Tests and diagnostics must never print real note text or overwrite the user's Application Support files. Validate counts, schema shape, or normalized hashes instead. Use an isolated temporary application-support directory for destructive persistence tests.
