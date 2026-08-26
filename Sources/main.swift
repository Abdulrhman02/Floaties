import AppKit
import QuartzCore
import SwiftUI
import UniformTypeIdentifiers

private let appName = "Floaties"

private struct PaletteColor: Identifiable, Equatable {
    let id: String
    let name: String
    let hex: String

    static let all: [PaletteColor] = [
        .init(id: "sun", name: "Sun", hex: "FFD45A"),
        .init(id: "coral", name: "Coral", hex: "FF947D"),
        .init(id: "mint", name: "Mint", hex: "78DDB7"),
        .init(id: "sky", name: "Sky", hex: "7BBEFF"),
        .init(id: "lavender", name: "Lavender", hex: "BAA1FF"),
        .init(id: "rose", name: "Rose", hex: "F49AB8"),
        .init(id: "sand", name: "Sand", hex: "EBCB91")
    ]
}

private extension Color {
    init(hex: String) {
        let cleaned = hex.trimmingCharacters(in: CharacterSet.alphanumerics.inverted)
        var value: UInt64 = 0
        Scanner(string: cleaned).scanHexInt64(&value)
        let r = Double((value >> 16) & 0xFF) / 255
        let g = Double((value >> 8) & 0xFF) / 255
        let b = Double(value & 0xFF) / 255
        self.init(red: r, green: g, blue: b)
    }
}

private final class WindowDragNSView: NSView {
    override func mouseDown(with event: NSEvent) {
        window?.performDrag(with: event)
    }

    override func resetCursorRects() {
        addCursorRect(bounds, cursor: .openHand)
    }
}

private struct WindowDragHandle: NSViewRepresentable {
    func makeNSView(context: Context) -> WindowDragNSView { WindowDragNSView() }
    func updateNSView(_ nsView: WindowDragNSView, context: Context) {}
}

private final class WindowResizeNSView: NSView {
    private var startingFrame: NSRect?
    private var startingPoint: NSPoint?

    override func mouseDown(with event: NSEvent) {
        guard let window else { return }
        startingFrame = window.frame
        startingPoint = window.convertPoint(toScreen: event.locationInWindow)
    }

    override func mouseDragged(with event: NSEvent) {
        guard let window, let startingFrame, let startingPoint else { return }
        let point = window.convertPoint(toScreen: event.locationInWindow)
        let deltaX = point.x - startingPoint.x
        let deltaY = point.y - startingPoint.y
        let newWidth = min(max(startingFrame.width + deltaX, 280), 520)
        let newHeight = min(max(startingFrame.height - deltaY, 180), 700)

        var frame = startingFrame
        frame.size.width = newWidth
        frame.size.height = newHeight
        frame.origin.y = startingFrame.maxY - newHeight
        window.setFrame(frame, display: true)
    }

    override func mouseUp(with event: NSEvent) {
        startingFrame = nil
        startingPoint = nil
    }

    override func resetCursorRects() {
        addCursorRect(bounds, cursor: .crosshair)
    }
}

private struct WindowResizeHandle: NSViewRepresentable {
    func makeNSView(context: Context) -> WindowResizeNSView { WindowResizeNSView() }
    func updateNSView(_ nsView: WindowResizeNSView, context: Context) {}
}

private struct TodoItem: Identifiable, Codable, Equatable {
    var id = UUID()
    var text = ""
    var isDone = false
}

private enum NoteBlockKind: String, Codable, Hashable {
    case text
    case checklist
    case heading
    case bullet
    case quote
    case divider

    var isTextual: Bool {
        switch self {
        case .text, .heading, .bullet, .quote: return true
        case .checklist, .divider: return false
        }
    }

    var displayName: String {
        switch self {
        case .text: return "Text"
        case .checklist: return "To-do"
        case .heading: return "Heading"
        case .bullet: return "Bulleted list"
        case .quote: return "Quote"
        case .divider: return "Divider"
        }
    }

    var systemImage: String {
        switch self {
        case .text: return "text.alignleft"
        case .checklist: return "checklist"
        case .heading: return "textformat.size.larger"
        case .bullet: return "list.bullet"
        case .quote: return "text.quote"
        case .divider: return "minus"
        }
    }
}

private struct NoteBlock: Identifiable, Codable, Equatable {
    var id = UUID()
    var kind: NoteBlockKind
    var text = ""
    var todos: [TodoItem] = []
    var indentLevel = 0
    var isSectionCollapsed = false

    init(id: UUID = UUID(), kind: NoteBlockKind, text: String = "",
         todos: [TodoItem] = [], indentLevel: Int = 0,
         isSectionCollapsed: Bool = false) {
        self.id = id
        self.kind = kind
        self.text = text
        self.todos = todos
        self.indentLevel = min(max(indentLevel, 0), 4)
        self.isSectionCollapsed = isSectionCollapsed
    }

    enum CodingKeys: String, CodingKey {
        case id, kind, text, todos, indentLevel, isSectionCollapsed
    }

    init(from decoder: Decoder) throws {
        let c = try decoder.container(keyedBy: CodingKeys.self)
        id = try c.decodeIfPresent(UUID.self, forKey: .id) ?? UUID()
        kind = try c.decode(NoteBlockKind.self, forKey: .kind)
        text = try c.decodeIfPresent(String.self, forKey: .text) ?? ""
        todos = try c.decodeIfPresent([TodoItem].self, forKey: .todos) ?? []
        indentLevel = min(max(try c.decodeIfPresent(Int.self, forKey: .indentLevel) ?? 0, 0), 4)
        isSectionCollapsed = try c.decodeIfPresent(Bool.self, forKey: .isSectionCollapsed) ?? false
    }

    func encode(to encoder: Encoder) throws {
        var c = encoder.container(keyedBy: CodingKeys.self)
        try c.encode(id, forKey: .id)
        try c.encode(kind, forKey: .kind)
        try c.encode(text, forKey: .text)
        try c.encode(todos, forKey: .todos)
        try c.encode(indentLevel, forKey: .indentLevel)
        if isSectionCollapsed {
            try c.encode(true, forKey: .isSectionCollapsed)
        }
    }

    static func text(_ value: String = "") -> NoteBlock {
        NoteBlock(kind: .text, text: value)
    }

    static func checklist(_ items: [TodoItem] = [TodoItem()]) -> NoteBlock {
        NoteBlock(kind: .checklist, todos: items)
    }

    static func textual(kind: NoteBlockKind, value: String = "") -> NoteBlock {
        NoteBlock(kind: kind, text: value)
    }

    static func normalized(_ source: [NoteBlock]) -> [NoteBlock] {
        var result: [NoteBlock] = []

        for block in source {
            switch block.kind {
            case .text, .heading, .bullet, .quote:
                let lines = block.text
                    .replacingOccurrences(of: "\r\n", with: "\n")
                    .replacingOccurrences(of: "\r", with: "\n")
                    .components(separatedBy: "\n")
                for (index, line) in lines.enumerated() {
                    result.append(NoteBlock(
                        id: index == 0 ? block.id : UUID(),
                        kind: block.kind,
                        text: line,
                        indentLevel: block.indentLevel
                    ))
                }
            case .checklist:
                let items = block.todos.isEmpty ? [TodoItem()] : block.todos
                for (index, item) in items.enumerated() {
                    result.append(NoteBlock(
                        id: index == 0 ? block.id : item.id,
                        kind: .checklist,
                        todos: [item],
                        indentLevel: block.indentLevel,
                        isSectionCollapsed: index == 0 && block.isSectionCollapsed
                    ))
                }
            case .divider:
                result.append(NoteBlock(id: block.id, kind: .divider))
            }
        }

        return result.isEmpty ? [.text()] : result
    }
}

private final class StickyNote: ObservableObject, Codable, Identifiable {
    let id: UUID
    @Published var title: String { didSet { changed() } }
    @Published var text: String { didSet { changed() } }
    @Published var todos: [TodoItem] { didSet { changed() } }
    @Published var isChecklist: Bool { didSet { changed() } }
    @Published var blocks: [NoteBlock] { didSet { changed() } }
    @Published var colorHex: String { didSet { changed() } }
    @Published var isPinned: Bool { didSet { changed() } }
    @Published var isCollapsed: Bool { didSet { changed() } }
    @Published var isDeleted: Bool { didSet { changed() } }
    @Published var deletedAt: Date? { didSet { changed() } }
    var x: Double { didSet { changed() } }
    var y: Double { didSet { changed() } }
    var width: Double { didSet { changed() } }
    var height: Double { didSet { changed() } }
    var expandedHeight: Double { didSet { changed() } }
    var onChange: (() -> Void)?

    init(id: UUID = UUID(), title: String = "", text: String = "", todos: [TodoItem] = [], isChecklist: Bool = false,
         blocks: [NoteBlock]? = nil,
         colorHex: String = PaletteColor.all[0].hex, isPinned: Bool = true,
         isCollapsed: Bool = false, isDeleted: Bool = false, deletedAt: Date? = nil,
         x: Double, y: Double, width: Double = 320,
         height: Double = 300, expandedHeight: Double = 300) {
        self.id = id
        self.title = title
        self.text = text
        self.todos = todos
        self.isChecklist = isChecklist
        self.blocks = NoteBlock.normalized(
            blocks ?? (isChecklist ? [.checklist(todos)] : [.text(text)])
        )
        self.colorHex = colorHex
        self.isPinned = isPinned
        self.isCollapsed = isCollapsed
        self.isDeleted = isDeleted
        self.deletedAt = deletedAt
        self.x = x
        self.y = y
        self.width = width
        self.height = height
        self.expandedHeight = expandedHeight
    }

    private func changed() { onChange?() }

    enum CodingKeys: String, CodingKey {
        case id, title, text, todos, isChecklist, blocks, colorHex, isPinned, isCollapsed, isDeleted, deletedAt
        case x, y, width, height, expandedHeight
    }

    required init(from decoder: Decoder) throws {
        let c = try decoder.container(keyedBy: CodingKeys.self)
        id = try c.decode(UUID.self, forKey: .id)
        title = try c.decodeIfPresent(String.self, forKey: .title) ?? ""
        let decodedText = try c.decodeIfPresent(String.self, forKey: .text) ?? ""
        let decodedTodos = try c.decodeIfPresent([TodoItem].self, forKey: .todos) ?? []
        let decodedIsChecklist = try c.decodeIfPresent(Bool.self, forKey: .isChecklist) ?? false
        text = decodedText
        todos = decodedTodos
        isChecklist = decodedIsChecklist
        let decodedBlocks = try c.decodeIfPresent([NoteBlock].self, forKey: .blocks)
            ?? (decodedIsChecklist ? [NoteBlock.checklist(decodedTodos)] : [NoteBlock.text(decodedText)])
        blocks = NoteBlock.normalized(decodedBlocks)
        colorHex = try c.decodeIfPresent(String.self, forKey: .colorHex) ?? PaletteColor.all[0].hex
        isPinned = try c.decodeIfPresent(Bool.self, forKey: .isPinned) ?? true
        isCollapsed = try c.decodeIfPresent(Bool.self, forKey: .isCollapsed) ?? false
        isDeleted = try c.decodeIfPresent(Bool.self, forKey: .isDeleted) ?? false
        deletedAt = try c.decodeIfPresent(Date.self, forKey: .deletedAt)
        x = try c.decode(Double.self, forKey: .x)
        y = try c.decode(Double.self, forKey: .y)
        width = try c.decodeIfPresent(Double.self, forKey: .width) ?? 320
        height = try c.decodeIfPresent(Double.self, forKey: .height) ?? 300
        expandedHeight = try c.decodeIfPresent(Double.self, forKey: .expandedHeight) ?? 300
    }

    func encode(to encoder: Encoder) throws {
        var c = encoder.container(keyedBy: CodingKeys.self)
        try c.encode(id, forKey: .id)
        try c.encode(title, forKey: .title)
        try c.encode(text, forKey: .text)
        try c.encode(todos, forKey: .todos)
        try c.encode(isChecklist, forKey: .isChecklist)
        try c.encode(blocks, forKey: .blocks)
        try c.encode(colorHex, forKey: .colorHex)
        try c.encode(isPinned, forKey: .isPinned)
        try c.encode(isCollapsed, forKey: .isCollapsed)
        try c.encode(isDeleted, forKey: .isDeleted)
        try c.encodeIfPresent(deletedAt, forKey: .deletedAt)
        try c.encode(x, forKey: .x)
        try c.encode(y, forKey: .y)
        try c.encode(width, forKey: .width)
        try c.encode(height, forKey: .height)
        try c.encode(expandedHeight, forKey: .expandedHeight)
    }
}

private struct HeaderButtonStyle: ButtonStyle {
    func makeBody(configuration: Configuration) -> some View {
        configuration.label
            .font(.system(size: 12, weight: .semibold, design: .rounded))
            .foregroundStyle(Color.black.opacity(configuration.isPressed ? 0.9 : 0.62))
            .frame(width: 25, height: 25)
            .background(Color.white.opacity(configuration.isPressed ? 0.42 : 0.24))
            .clipShape(Circle())
    }
}

private struct HeaderMenuLabel: View {
    let systemName: String

    var body: some View {
        Image(systemName: systemName)
            .font(.system(size: 12, weight: .semibold, design: .rounded))
            .foregroundStyle(Color.black.opacity(0.62))
            .frame(width: 25, height: 25)
    }
}

private final class NavigableTodoTextField: NSTextField {}

private final class NavigableBlockTextField: NSTextField {}

private struct BlockTextField: NSViewRepresentable {
    @Binding var text: String
    @Binding var focusedBlockID: UUID?
    let blockID: UUID
    let kind: NoteBlockKind
    let focusAtStart: Bool
    let onSubmit: (Int) -> Void
    let onMove: (Int) -> Void
    let onBackspaceAtStart: () -> Void
    let onTextChanged: (String) -> Void
    let onFocused: () -> Void

    final class Coordinator: NSObject, NSTextFieldDelegate {
        var parent: BlockTextField

        init(parent: BlockTextField) {
            self.parent = parent
        }

        func controlTextDidBeginEditing(_ notification: Notification) {
            parent.focusedBlockID = parent.blockID
            parent.onFocused()
        }

        func controlTextDidEndEditing(_ notification: Notification) {
            if parent.focusedBlockID == parent.blockID {
                parent.focusedBlockID = nil
            }
        }

        func controlTextDidChange(_ notification: Notification) {
            guard let field = notification.object as? NSTextField else { return }
            parent.text = field.stringValue
            parent.onTextChanged(field.stringValue)
        }

        func control(_ control: NSControl, textView: NSTextView,
                     doCommandBy commandSelector: Selector) -> Bool {
            switch NSStringFromSelector(commandSelector) {
            case "moveUp:":
                parent.onMove(-1)
                return true
            case "moveDown:":
                parent.onMove(1)
                return true
            case "insertNewline:", "insertNewlineIgnoringFieldEditor:":
                parent.onSubmit(textView.selectedRange().location)
                return true
            case "deleteBackward:":
                if textView.selectedRange().location == 0 {
                    parent.onBackspaceAtStart()
                    return true
                }
                return false
            default:
                return false
            }
        }
    }

    func makeCoordinator() -> Coordinator { Coordinator(parent: self) }

    private var configuredFont: NSFont {
        let size: CGFloat = kind == .heading ? 20 : 16
        let weight: NSFont.Weight = kind == .heading ? .bold : .medium
        let base = NSFont.systemFont(ofSize: size, weight: weight)
        let rounded = base.fontDescriptor.withDesign(.rounded)
            .flatMap { NSFont(descriptor: $0, size: size) } ?? base
        guard kind == .quote else {
            return rounded
        }
        let italicDescriptor = rounded.fontDescriptor.withSymbolicTraits(.italic)
        return NSFont(descriptor: italicDescriptor, size: size) ?? rounded
    }

    private var focusedPlaceholder: String {
        switch kind {
        case .text: return "Type '/' for commands"
        case .heading: return "Heading"
        case .bullet: return "List item"
        case .quote: return "Quote"
        case .checklist, .divider: return ""
        }
    }

    func makeNSView(context: Context) -> NavigableBlockTextField {
        let field = NavigableBlockTextField()
        field.delegate = context.coordinator
        field.isBordered = false
        field.drawsBackground = false
        field.focusRingType = .none
        field.isEditable = true
        field.isSelectable = true
        field.maximumNumberOfLines = 1
        field.lineBreakMode = .byTruncatingTail
        field.cell?.isScrollable = true
        field.cell?.usesSingleLineMode = true

        field.font = configuredFont
        field.placeholderAttributedString = nil
        return field
    }

    func updateNSView(_ field: NavigableBlockTextField, context: Context) {
        context.coordinator.parent = self
        if field.stringValue != text {
            field.stringValue = text
        }
        field.font = configuredFont
        field.textColor = NSColor.black.withAlphaComponent(kind == .quote ? 0.66 : 0.78)
        field.placeholderAttributedString = focusedBlockID == blockID
            ? NSAttributedString(
                string: focusedPlaceholder,
                attributes: [
                    .foregroundColor: NSColor.black.withAlphaComponent(0.30),
                    .font: configuredFont
                ]
            )
            : nil

        if focusedBlockID == blockID, field.currentEditor() == nil {
            let shouldFocusAtStart = focusAtStart
            DispatchQueue.main.async { [weak field] in
                guard let field, field.currentEditor() == nil else { return }
                field.window?.makeFirstResponder(field)
                if let editor = field.currentEditor() {
                    editor.selectedRange = NSRange(
                        location: shouldFocusAtStart ? 0 : field.stringValue.utf16.count,
                        length: 0
                    )
                }
            }
        }
    }
}

private struct TodoTextField: NSViewRepresentable {
    @Binding var text: String
    @Binding var focusedItemID: UUID?
    let itemID: UUID
    let isDone: Bool
    let focusAtStart: Bool
    let onSubmit: (Int) -> Void
    let onInsertTextAfter: () -> Void
    let onIndent: () -> Void
    let onOutdent: () -> Void
    let onMove: (Int) -> Void
    let onRequestDelete: () -> Void
    let onFocused: () -> Void

    final class Coordinator: NSObject, NSTextFieldDelegate {
        var parent: TodoTextField

        init(parent: TodoTextField) {
            self.parent = parent
        }

        func controlTextDidBeginEditing(_ notification: Notification) {
            parent.focusedItemID = parent.itemID
            parent.onFocused()
        }

        func controlTextDidEndEditing(_ notification: Notification) {
            if parent.focusedItemID == parent.itemID {
                parent.focusedItemID = nil
            }
        }

        func controlTextDidChange(_ notification: Notification) {
            guard let field = notification.object as? NSTextField else { return }
            parent.text = field.stringValue
        }

        func control(_ control: NSControl, textView: NSTextView,
                     doCommandBy commandSelector: Selector) -> Bool {
            switch NSStringFromSelector(commandSelector) {
            case "moveUp:":
                parent.onMove(-1)
                return true
            case "moveDown:":
                parent.onMove(1)
                return true
            case "insertNewline:", "insertNewlineIgnoringFieldEditor:":
                let cursorLocation = textView.selectedRange().location
                if NSApp.currentEvent?.modifierFlags.contains(.shift) == true {
                    parent.onInsertTextAfter()
                } else {
                    parent.onSubmit(cursorLocation)
                }
                return true
            case "insertTab:":
                parent.onIndent()
                return true
            case "insertBacktab:":
                parent.onOutdent()
                return true
            case "deleteBackward:", "deleteForward:":
                if textView.string.isEmpty {
                    parent.onRequestDelete()
                    return true
                }
                return false
            default:
                return false
            }
        }
    }

    func makeCoordinator() -> Coordinator { Coordinator(parent: self) }

    func makeNSView(context: Context) -> NavigableTodoTextField {
        let field = NavigableTodoTextField()
        field.delegate = context.coordinator
        field.isBordered = false
        field.drawsBackground = false
        field.focusRingType = .none
        field.isEditable = true
        field.isSelectable = true
        field.maximumNumberOfLines = 1
        field.lineBreakMode = .byTruncatingTail
        field.cell?.isScrollable = true
        field.cell?.usesSingleLineMode = true

        let baseFont = NSFont.systemFont(ofSize: 15, weight: .medium)
        if let rounded = baseFont.fontDescriptor.withDesign(.rounded),
           let font = NSFont(descriptor: rounded, size: 15) {
            field.font = font
        } else {
            field.font = baseFont
        }
        field.placeholderAttributedString = nil

        return field
    }

    func updateNSView(_ field: NavigableTodoTextField, context: Context) {
        context.coordinator.parent = self
        if field.stringValue != text {
            field.stringValue = text
        }
        field.textColor = NSColor.black.withAlphaComponent(isDone ? 0.46 : 0.78)
        field.placeholderAttributedString = focusedItemID == itemID
            ? NSAttributedString(
                string: "To-do",
                attributes: [
                    .foregroundColor: NSColor.black.withAlphaComponent(0.28),
                    .font: field.font ?? NSFont.systemFont(ofSize: 15, weight: .medium)
                ]
            )
            : nil

        if focusedItemID == itemID, field.currentEditor() == nil {
            DispatchQueue.main.async { [weak field] in
                guard let field, field.currentEditor() == nil else { return }
                field.window?.makeFirstResponder(field)
                if let editor = field.currentEditor() {
                    editor.selectedRange = NSRange(
                        location: focusAtStart ? 0 : field.stringValue.utf16.count,
                        length: 0
                    )
                }
            }
        }
    }
}

private struct TodoRow: View {
    @Binding var item: TodoItem
    @Binding var focusedBlockID: UUID?
    let blockID: UUID
    let focusAtStart: Bool
    let onSubmit: (Int) -> Void
    let onInsertTextAfter: () -> Void
    let onIndent: () -> Void
    let onOutdent: () -> Void
    let onMove: (Int) -> Void
    let onRequestDelete: () -> Void
    let onFocused: () -> Void

    var body: some View {
        HStack(spacing: 8) {
            Button {
                item.isDone.toggle()
            } label: {
                Image(systemName: item.isDone ? "checkmark.circle.fill" : "circle")
                    .font(.system(size: 17, weight: .medium))
                    .foregroundStyle(Color.black.opacity(item.isDone ? 0.62 : 0.43))
            }
            .buttonStyle(.plain)

            TodoTextField(
                text: $item.text,
                focusedItemID: $focusedBlockID,
                itemID: blockID,
                isDone: item.isDone,
                focusAtStart: focusAtStart,
                onSubmit: onSubmit,
                onInsertTextAfter: onInsertTextAfter,
                onIndent: onIndent,
                onOutdent: onOutdent,
                onMove: onMove,
                onRequestDelete: onRequestDelete,
                onFocused: onFocused
            )
        }
        .padding(.vertical, 2)
    }
}

private struct BlockDropDelegate: DropDelegate {
    let targetID: UUID
    @Binding var blocks: [NoteBlock]
    @Binding var draggedID: UUID?

    func dropEntered(info: DropInfo) {
        guard let draggedID,
              draggedID != targetID,
              let sourceIndex = blocks.firstIndex(where: { $0.id == draggedID }),
              let targetIndex = blocks.firstIndex(where: { $0.id == targetID }) else { return }

        withAnimation(.easeInOut(duration: 0.14)) {
            blocks.move(
                fromOffsets: IndexSet(integer: sourceIndex),
                toOffset: targetIndex > sourceIndex ? targetIndex + 1 : targetIndex
            )
        }
    }

    func dropUpdated(info: DropInfo) -> DropProposal? {
        DropProposal(operation: .move)
    }

    func performDrop(info: DropInfo) -> Bool {
        draggedID = nil
        return true
    }
}

private struct SlashSuggestion: Identifiable {
    let kind: NoteBlockKind
    let detail: String
    let command: String

    var id: NoteBlockKind { kind }
}

private struct SlashSuggestionRow: View {
    let suggestion: SlashSuggestion
    let isSelected: Bool
    let action: () -> Void
    let onHighlight: () -> Void
    @State private var isHovering = false

    var body: some View {
        Button(action: action) {
            HStack(spacing: 9) {
                RoundedRectangle(cornerRadius: 6, style: .continuous)
                    .fill(Color.black.opacity(0.055))
                    .frame(width: 27, height: 27)
                    .overlay {
                        Image(systemName: suggestion.kind.systemImage)
                            .font(.system(size: 13, weight: .semibold))
                            .foregroundStyle(Color.black.opacity(0.64))
                    }

                VStack(alignment: .leading, spacing: 1) {
                    Text(suggestion.kind.displayName)
                        .font(.system(size: 12, weight: .semibold, design: .rounded))
                    Text(suggestion.detail)
                        .font(.system(size: 9, weight: .medium, design: .rounded))
                        .foregroundStyle(Color.black.opacity(0.42))
                        .lineLimit(1)
                }

                Spacer(minLength: 5)

                Text(suggestion.command)
                    .font(.system(size: 9, weight: .semibold, design: .monospaced))
                    .foregroundStyle(Color.black.opacity(0.34))
            }
            .foregroundStyle(Color.black.opacity(0.76))
            .padding(.horizontal, 7)
            .frame(height: 35)
            .background(
                RoundedRectangle(cornerRadius: 7, style: .continuous)
                    .fill(Color.black.opacity(isHovering || isSelected ? 0.075 : 0))
            )
            .contentShape(Rectangle())
        }
        .buttonStyle(.plain)
        .onHover {
            isHovering = $0
            if $0 { onHighlight() }
        }
    }
}

private struct BlockSection: Identifiable {
    let kind: NoteBlockKind
    var blockIDs: [UUID]

    var id: UUID { blockIDs[0] }
}

private struct StickyNoteView: View {
    @ObservedObject var note: StickyNote
    @State private var focusedBlockID: UUID?
    @State private var focusAtStartID: UUID?
    @State private var pendingDeleteID: UUID?
    @State private var draggedBlockID: UUID?
    @State private var hoveredBlockID: UUID?
    @State private var selectedSlashIndex = 0
    let onNew: () -> Void
    let onClose: () -> Void
    let onDashboard: () -> Void
    let onTogglePin: () -> Void
    let onToggleCollapse: () -> Void

    private var noteColor: Color { Color(hex: note.colorHex) }

    private var blockSections: [BlockSection] {
        var sections: [BlockSection] = []
        for block in note.blocks {
            if let lastIndex = sections.indices.last,
               sections[lastIndex].kind == block.kind {
                sections[lastIndex].blockIDs.append(block.id)
            } else {
                sections.append(BlockSection(kind: block.kind, blockIDs: [block.id]))
            }
        }
        return sections
    }

    var body: some View {
        VStack(spacing: 0) {
            header
                .frame(height: 42)

            if !note.isCollapsed {
                Divider().overlay(Color.black.opacity(0.08))
                content
                    .transition(.opacity)
            }
        }
        .background(noteColor)
        .clipShape(RoundedRectangle(cornerRadius: 15, style: .continuous))
        .overlay {
            RoundedRectangle(cornerRadius: 15, style: .continuous)
                .strokeBorder(Color.white.opacity(0.42), lineWidth: 1)
        }
        .overlay(alignment: .bottomTrailing) {
            if !note.isCollapsed {
                ZStack {
                    WindowResizeHandle()
                    Image(systemName: "arrow.up.left.and.arrow.down.right")
                        .font(.system(size: 9, weight: .bold))
                        .foregroundStyle(Color.black.opacity(0.28))
                        .allowsHitTesting(false)
                }
                .frame(width: 25, height: 25)
                .help("Drag to resize")
            }
        }
        .padding(6)
        .alert("Delete this to-do?", isPresented: deleteAlertIsPresented) {
            Button("Cancel", role: .cancel) {
                pendingDeleteID = nil
            }
            .keyboardShortcut(.cancelAction)

            Button("Delete", role: .destructive) {
                confirmDelete()
            }
            .keyboardShortcut(.defaultAction)
        } message: {
            Text("This removes the item from this sticky note.")
        }
    }

    private var header: some View {
        HStack(spacing: 4) {
            ZStack {
                WindowDragHandle()
                Image(systemName: "circle.grid.3x3.fill")
                    .font(.system(size: 11))
                    .foregroundStyle(Color.black.opacity(0.28))
                    .allowsHitTesting(false)
            }
            .frame(width: 20, height: 28)
            .padding(.leading, 2)
            .help("Drag the note")

            ZStack(alignment: .leading) {
                if note.title.isEmpty {
                    Text("Title")
                        .font(.system(size: 11, weight: .semibold, design: .rounded))
                        .foregroundStyle(Color.black.opacity(0.27))
                        .allowsHitTesting(false)
                }

                TextField("", text: $note.title)
                    .textFieldStyle(.plain)
                    .font(.system(size: 12, weight: .bold, design: .rounded))
                    .foregroundStyle(Color.black.opacity(0.72))
                    .lineLimit(1)
                    .accessibilityLabel("Note title")
            }
            .frame(minWidth: 32, maxWidth: .infinity)
            .layoutPriority(1)

            Button(action: onTogglePin) {
                Image(systemName: note.isPinned ? "pin.fill" : "pin")
            }
            .buttonStyle(HeaderButtonStyle())
            .help(note.isPinned
                  ? "Unpin and keep on this Desktop"
                  : "Keep above apps and follow across Desktops")

            Menu {
                ForEach(PaletteColor.all) { swatch in
                    Button {
                        note.colorHex = swatch.hex
                    } label: {
                        Label(swatch.name, systemImage: swatch.hex == note.colorHex ? "checkmark.circle.fill" : "circle.fill")
                    }
                }
            } label: {
                HeaderMenuLabel(systemName: "paintpalette.fill")
            }
            .menuStyle(.borderlessButton)
            .menuIndicator(.hidden)
            .tint(Color.black.opacity(0.62))
            .frame(width: 25, height: 25)
            .background(Color.white.opacity(0.24))
            .clipShape(Circle())
            .help("Choose color")

            Button(action: onDashboard) {
                Image(systemName: "square.grid.2x2.fill")
            }
            .buttonStyle(HeaderButtonStyle())
            .help("Open notes dashboard")

            Button(action: onNew) {
                Image(systemName: "doc.badge.plus")
            }
            .buttonStyle(HeaderButtonStyle())
            .help("Create a new note")

            Button(action: onToggleCollapse) {
                Image(systemName: note.isCollapsed ? "chevron.down" : "chevron.up")
            }
            .buttonStyle(HeaderButtonStyle())
            .help(note.isCollapsed ? "Expand" : "Collapse")

            Button(action: onClose) {
                Image(systemName: "xmark")
            }
            .buttonStyle(HeaderButtonStyle())
            .help("Move to Recently Deleted")
        }
        .padding(.horizontal, 7)
        .contentShape(Rectangle())
    }

    private var content: some View {
        VStack(spacing: 0) {
            ScrollView {
                LazyVStack(spacing: 8) {
                    ForEach(blockSections) { section in
                        if section.kind == .checklist {
                            checklistSection(section)
                        } else {
                            VStack(spacing: 1) {
                                ForEach(section.blockIDs, id: \.self) { blockID in
                                    if let block = binding(for: blockID) {
                                        blockView(block: block)
                                    }
                                }
                            }
                        }
                    }
                }
                .padding(.horizontal, 9)
                .padding(.vertical, 9)
            }

            HStack(spacing: 7) {
                Menu {
                    Button("Text") { appendBlock(kind: .text) }
                    Button("To-do") { appendBlock(kind: .checklist) }
                    Divider()
                    Button("Heading") { appendBlock(kind: .heading) }
                    Button("Bulleted list") { appendBlock(kind: .bullet) }
                    Button("Quote") { appendBlock(kind: .quote) }
                    Button("Divider") { appendBlock(kind: .divider) }
                } label: {
                    Image(systemName: "plus.circle.fill")
                        .font(.system(size: 13, weight: .semibold))
                        .foregroundStyle(Color.black.opacity(0.42))
                }
                .menuStyle(.borderlessButton)
                .menuIndicator(.hidden)
                .tint(Color.black.opacity(0.42))
                .frame(width: 18)

                Text("Add block")
                Spacer()
            }
            .buttonStyle(.plain)
            .font(.system(size: 10, weight: .medium, design: .rounded))
            .foregroundStyle(Color.black.opacity(0.34))
            .padding(.horizontal, 14)
            .padding(.bottom, 10)
        }
    }

    private func checklistSection(_ section: BlockSection) -> some View {
        let isCollapsed = sectionIsCollapsed(section)

        return VStack(spacing: 2) {
            Button {
                toggleChecklistSection(section)
            } label: {
                HStack(spacing: 5) {
                    Image(systemName: isCollapsed ? "chevron.right" : "chevron.down")
                        .frame(width: 9)
                    Image(systemName: "checklist")
                    Text("CHECKLIST")
                    Spacer()
                    Text("\(section.blockIDs.count)")
                }
                .contentShape(Rectangle())
            }
            .buttonStyle(.plain)
            .font(.system(size: 9, weight: .bold, design: .rounded))
            .foregroundStyle(Color.black.opacity(0.34))
            .padding(.horizontal, 10)
            .padding(.top, 8)
            .padding(.bottom, isCollapsed ? 8 : 2)
            .help(isCollapsed ? "Expand checklist" : "Collapse checklist")

            if !isCollapsed {
                ForEach(section.blockIDs, id: \.self) { blockID in
                    if let block = binding(for: blockID) {
                        blockView(block: block)
                    }
                }

                Button {
                    if let lastID = section.blockIDs.last {
                        appendTodo(after: lastID)
                    }
                } label: {
                    Label("Add item", systemImage: "plus.circle.fill")
                        .font(.system(size: 11, weight: .semibold, design: .rounded))
                        .foregroundStyle(Color.black.opacity(0.44))
                }
                .buttonStyle(.plain)
                .frame(maxWidth: .infinity, alignment: .leading)
                .padding(.leading, 27)
                .padding(.top, 2)
                .padding(.bottom, 9)
            }
        }
        .background(Color.white.opacity(0.17))
        .clipShape(RoundedRectangle(cornerRadius: 11, style: .continuous))
        .overlay {
            RoundedRectangle(cornerRadius: 11, style: .continuous)
                .strokeBorder(Color.white.opacity(0.16), lineWidth: 1)
        }
        .animation(.easeInOut(duration: 0.16), value: isCollapsed)
    }

    private func sectionIsCollapsed(_ section: BlockSection) -> Bool {
        guard let anchorID = section.blockIDs.first,
              let anchor = note.blocks.first(where: { $0.id == anchorID }) else { return false }
        return anchor.isSectionCollapsed
    }

    private func toggleChecklistSection(_ section: BlockSection) {
        guard let anchorID = section.blockIDs.first,
              let index = note.blocks.firstIndex(where: { $0.id == anchorID }) else { return }
        let willCollapse = !note.blocks[index].isSectionCollapsed
        if willCollapse, let focusedBlockID, section.blockIDs.contains(focusedBlockID) {
            self.focusedBlockID = nil
            focusAtStartID = nil
        }
        note.blocks[index].isSectionCollapsed = willCollapse
    }

    private func binding(for blockID: UUID) -> Binding<NoteBlock>? {
        guard let index = note.blocks.firstIndex(where: { $0.id == blockID }) else { return nil }
        return $note.blocks[index]
    }

    @ViewBuilder private func blockView(block: Binding<NoteBlock>) -> some View {
        VStack(alignment: .leading, spacing: 2) {
            HStack(spacing: 3) {
                VStack(spacing: 2) {
                    ForEach(0..<3, id: \.self) { _ in
                        HStack(spacing: 2) {
                            Circle().frame(width: 2.5, height: 2.5)
                            Circle().frame(width: 2.5, height: 2.5)
                        }
                    }
                }
                    .foregroundStyle(Color.black.opacity(0.46))
                    .frame(width: 13, height: 25)
                    .contentShape(Rectangle())
                    .opacity(
                        hoveredBlockID == block.wrappedValue.id || draggedBlockID == block.wrappedValue.id
                            ? 1 : 0
                    )
                    .animation(.easeOut(duration: 0.12), value: hoveredBlockID)
                    .onDrag {
                        draggedBlockID = block.wrappedValue.id
                        return NSItemProvider(object: block.wrappedValue.id.uuidString as NSString)
                    }
                    .help("Drag to reorder")

                Group {
                    if block.wrappedValue.kind == .divider {
                        Rectangle()
                            .fill(Color.black.opacity(0.22))
                            .frame(maxWidth: .infinity)
                            .frame(height: 1)
                            .padding(.vertical, 11)
                            .accessibilityLabel("Divider")
                    } else if block.wrappedValue.kind.isTextual {
                        HStack(spacing: 7) {
                            if block.wrappedValue.kind == .bullet {
                                Circle()
                                    .fill(Color.black.opacity(0.58))
                                    .frame(width: 5, height: 5)
                            } else if block.wrappedValue.kind == .quote {
                                RoundedRectangle(cornerRadius: 1.5)
                                    .fill(Color.black.opacity(0.42))
                                    .frame(width: 3, height: 21)
                            }

                            BlockTextField(
                                text: block.text,
                                focusedBlockID: $focusedBlockID,
                                blockID: block.wrappedValue.id,
                                kind: block.wrappedValue.kind,
                                focusAtStart: focusAtStartID == block.wrappedValue.id,
                                onSubmit: { submitTextBlock(id: block.wrappedValue.id, cursor: $0) },
                                onMove: { handleTextMove(from: block.wrappedValue.id, by: $0) },
                                onBackspaceAtStart: { backspaceAtStart(of: block.wrappedValue.id) },
                                onTextChanged: { value in
                                    if slashQuery(value) != nil { selectedSlashIndex = 0 }
                                },
                                onFocused: {
                                    if focusAtStartID == block.wrappedValue.id { focusAtStartID = nil }
                                }
                            )
                            .frame(height: block.wrappedValue.kind == .heading ? 32 : 27)
                        }
                    } else {
                        ForEach(block.todos) { $item in
                            TodoRow(
                                item: $item,
                                focusedBlockID: $focusedBlockID,
                                blockID: block.wrappedValue.id,
                                focusAtStart: focusAtStartID == block.wrappedValue.id,
                                onSubmit: { submitTodoBlock(id: block.wrappedValue.id, cursor: $0) },
                                onInsertTextAfter: { insertText(after: block.wrappedValue.id) },
                                onIndent: { changeIndent(of: block.wrappedValue.id, by: 1) },
                                onOutdent: { changeIndent(of: block.wrappedValue.id, by: -1) },
                                onMove: { moveFocus(from: block.wrappedValue.id, by: $0) },
                                onRequestDelete: { pendingDeleteID = item.id },
                                onFocused: {
                                    if focusAtStartID == block.wrappedValue.id { focusAtStartID = nil }
                                }
                            )
                        }
                    }
                }
                .padding(.leading, CGFloat(block.wrappedValue.indentLevel) * 20)
            }
            .padding(.horizontal, 2)
            .contentShape(Rectangle())

            if block.wrappedValue.kind == .text,
               focusedBlockID == block.wrappedValue.id,
               slashQuery(block.wrappedValue.text) != nil {
                slashMenu(for: block.wrappedValue.id, query: slashQuery(block.wrappedValue.text) ?? "")
                    .padding(.leading, 20)
                    .padding(.trailing, 4)
            }
        }
        .onDrop(
            of: [UTType.text],
            delegate: BlockDropDelegate(
                targetID: block.wrappedValue.id,
                blocks: $note.blocks,
                draggedID: $draggedBlockID
            )
        )
        .contextMenu {
            if block.wrappedValue.kind.isTextual {
                Button("Turn into to-do") { turnIntoTodo(id: block.wrappedValue.id) }
            } else {
                Button("Turn into text") { turnIntoText(id: block.wrappedValue.id) }
            }
            Divider()
            Button("Delete block", role: .destructive) {
                deleteBlock(id: block.wrappedValue.id)
            }
        }
        .contentShape(Rectangle())
        .onHover { isHovering in
            if isHovering {
                hoveredBlockID = block.wrappedValue.id
            } else if hoveredBlockID == block.wrappedValue.id {
                hoveredBlockID = nil
            }
        }
    }

    private func slashMenu(for blockID: UUID, query: String) -> some View {
        let filtered = filteredSlashSuggestions(query: query)
        let selectedIndex = filtered.isEmpty
            ? 0
            : min(max(selectedSlashIndex, 0), filtered.count - 1)

        return VStack(alignment: .leading, spacing: 3) {
            HStack {
                VStack(alignment: .leading, spacing: 1) {
                    Text("Block suggestions")
                        .font(.system(size: 10, weight: .bold, design: .rounded))
                    Text("Choose what this line becomes")
                        .font(.system(size: 8, weight: .medium, design: .rounded))
                        .foregroundStyle(Color.black.opacity(0.40))
                }
                Spacer()
                Image(systemName: "return")
                    .font(.system(size: 9, weight: .semibold))
                    .foregroundStyle(Color.black.opacity(0.26))
            }
            .foregroundStyle(Color.black.opacity(0.68))
            .padding(.horizontal, 9)
            .padding(.top, 6)
            .padding(.bottom, 2)

            ForEach(Array(filtered.enumerated()), id: \.element.id) { index, suggestion in
                SlashSuggestionRow(
                    suggestion: suggestion,
                    isSelected: index == selectedIndex,
                    action: { applySlashCommand(to: blockID, kind: suggestion.kind) },
                    onHighlight: { selectedSlashIndex = index }
                )
            }

            if filtered.isEmpty {
                Text("No matching block")
                    .font(.system(size: 11, weight: .medium, design: .rounded))
                    .foregroundStyle(Color.black.opacity(0.38))
                    .padding(8)
            }
        }
        .padding(4)
        .frame(width: min(max(note.width - 86, 210), 292), alignment: .leading)
        .background(Color(red: 0.98, green: 0.97, blue: 0.93).opacity(0.98))
        .clipShape(RoundedRectangle(cornerRadius: 12, style: .continuous))
        .overlay {
            RoundedRectangle(cornerRadius: 12, style: .continuous)
                .strokeBorder(Color.black.opacity(0.12), lineWidth: 1)
        }
        .shadow(color: Color.black.opacity(0.18), radius: 14, y: 7)
    }

    private var slashSuggestions: [SlashSuggestion] {
        [
            SlashSuggestion(kind: .text, detail: "Plain writing", command: "/text"),
            SlashSuggestion(kind: .checklist, detail: "Track something to finish", command: "/todo"),
            SlashSuggestion(kind: .heading, detail: "A section title", command: "/heading"),
            SlashSuggestion(kind: .bullet, detail: "A simple bulleted item", command: "/bullet"),
            SlashSuggestion(kind: .quote, detail: "Emphasize a passage", command: "/quote"),
            SlashSuggestion(kind: .divider, detail: "Separate sections", command: "/divider")
        ]
    }

    private func filteredSlashSuggestions(query: String) -> [SlashSuggestion] {
        let normalizedQuery = query.lowercased().replacingOccurrences(of: "-", with: "")
        return slashSuggestions.filter {
            normalizedQuery.isEmpty || $0.kind.displayName.lowercased()
                .replacingOccurrences(of: "-", with: "")
                .contains(normalizedQuery)
                || $0.command.dropFirst().contains(normalizedQuery)
        }
    }

    private func slashQuery(_ value: String) -> String? {
        guard value.hasPrefix("/"), !value.contains(where: { $0.isWhitespace }) else { return nil }
        return String(value.dropFirst())
    }

    private func selectedSlashSuggestion(query: String) -> SlashSuggestion? {
        let suggestions = filteredSlashSuggestions(query: query)
        guard !suggestions.isEmpty else { return nil }
        let index = min(max(selectedSlashIndex, 0), suggestions.count - 1)
        return suggestions[index]
    }

    private func handleTextMove(from blockID: UUID, by offset: Int) {
        if focusedBlockID == blockID,
           let block = note.blocks.first(where: { $0.id == blockID }),
           let query = slashQuery(block.text) {
            let suggestions = filteredSlashSuggestions(query: query)
            guard !suggestions.isEmpty else { return }
            selectedSlashIndex = (selectedSlashIndex + offset + suggestions.count) % suggestions.count
            return
        }

        moveFocus(from: blockID, by: offset)
    }

    private func applySlashCommand(to blockID: UUID, kind: NoteBlockKind) {
        guard let index = note.blocks.firstIndex(where: { $0.id == blockID }) else { return }
        if kind == .checklist {
            note.blocks[index] = NoteBlock(id: blockID, kind: .checklist, todos: [TodoItem()])
        } else if kind == .divider {
            note.blocks[index] = NoteBlock(id: blockID, kind: .divider)
            let next = NoteBlock.text()
            note.blocks.insert(next, at: index + 1)
            focusAtStartID = next.id
            focusedBlockID = next.id
        } else {
            note.blocks[index] = NoteBlock(id: blockID, kind: kind)
            focusAtStartID = blockID
            focusedBlockID = blockID
        }
        selectedSlashIndex = 0
    }

    private func appendBlock(kind: NoteBlockKind) {
        let block: NoteBlock
        if kind == .checklist {
            block = NoteBlock.checklist()
        } else if kind == .divider {
            block = NoteBlock(kind: .divider)
        } else {
            block = NoteBlock.textual(kind: kind)
        }
        note.blocks.append(block)
        let focusBlock: NoteBlock
        if kind == .divider {
            focusBlock = NoteBlock.text()
            note.blocks.append(focusBlock)
        } else {
            focusBlock = block
        }
        DispatchQueue.main.async {
            focusedBlockID = focusBlock.id
        }
    }

    private func submitTextBlock(id: UUID, cursor: Int) {
        guard let index = note.blocks.firstIndex(where: { $0.id == id }) else { return }
        let value = note.blocks[index].text
        let trimmedValue = value.trimmingCharacters(in: .whitespacesAndNewlines)
        let loweredValue = trimmedValue.lowercased()
        let currentKind = note.blocks[index].kind

        if let query = slashQuery(value),
           let suggestion = selectedSlashSuggestion(query: query) {
            applySlashCommand(to: id, kind: suggestion.kind)
            return
        }

        let commands: [(String, NoteBlockKind)] = [
            ("/text", .text),
            ("/todo", .checklist),
            ("/to-do", .checklist),
            ("/checklist", .checklist),
            ("/heading", .heading),
            ("/bullet", .bullet),
            ("/quote", .quote),
            ("/divider", .divider)
        ]
        for (command, kind) in commands {
            if loweredValue == command {
                applySlashCommand(to: id, kind: kind)
                return
            }
            let prefix = command + " "
            if loweredValue.hasPrefix(prefix) {
                let commandText = String(trimmedValue.dropFirst(prefix.count))
                if kind == .checklist {
                    note.blocks[index] = NoteBlock(
                        id: id,
                        kind: .checklist,
                        todos: [TodoItem(text: commandText)]
                    )
                    focusedBlockID = id
                } else if kind == .divider {
                    note.blocks[index] = NoteBlock(id: id, kind: .divider)
                    let next = NoteBlock.text(commandText)
                    note.blocks.insert(next, at: index + 1)
                    focusAtStartID = next.id
                    focusedBlockID = next.id
                } else {
                    note.blocks[index] = NoteBlock(id: id, kind: kind, text: commandText)
                    focusedBlockID = id
                }
                return
            }
        }

        if value.isEmpty, currentKind != .text {
            note.blocks[index] = NoteBlock(id: id, kind: .text)
            focusAtStartID = id
            focusedBlockID = id
            return
        }

        let nsValue = value as NSString
        let splitPoint = min(max(cursor, 0), nsValue.length)
        note.blocks[index].text = nsValue.substring(to: splitPoint)
        let nextKind: NoteBlockKind = currentKind == .bullet ? .bullet : .text
        let next = NoteBlock.textual(kind: nextKind, value: nsValue.substring(from: splitPoint))
        note.blocks.insert(next, at: index + 1)
        focusAtStartID = next.id
        focusedBlockID = next.id
    }

    private func submitTodoBlock(id blockID: UUID, cursor: Int) {
        guard let index = note.blocks.firstIndex(where: { $0.id == blockID }) else { return }
        guard let item = note.blocks[index].todos.first else { return }

        if item.text.isEmpty {
            note.blocks[index] = NoteBlock(
                id: blockID,
                kind: .text
            )
            focusAtStartID = blockID
            focusedBlockID = blockID
            return
        }

        let nsValue = item.text as NSString
        let splitPoint = min(max(cursor, 0), nsValue.length)
        note.blocks[index].todos[0].text = nsValue.substring(to: splitPoint)
        let next = NoteBlock(
            kind: .checklist,
            todos: [TodoItem(text: nsValue.substring(from: splitPoint))],
            indentLevel: note.blocks[index].indentLevel
        )
        note.blocks.insert(next, at: index + 1)
        focusAtStartID = next.id
        focusedBlockID = next.id
    }

    private func insertText(after blockID: UUID) {
        guard let index = note.blocks.firstIndex(where: { $0.id == blockID }) else { return }
        let next = NoteBlock.text()
        note.blocks.insert(next, at: index + 1)
        focusAtStartID = next.id
        focusedBlockID = next.id
    }

    private func appendTodo(after blockID: UUID) {
        guard let index = note.blocks.firstIndex(where: { $0.id == blockID }) else { return }
        let next = NoteBlock(
            kind: .checklist,
            todos: [TodoItem()],
            indentLevel: note.blocks[index].indentLevel
        )
        note.blocks.insert(next, at: index + 1)
        focusAtStartID = next.id
        focusedBlockID = next.id
    }

    private func changeIndent(of blockID: UUID, by offset: Int) {
        guard let index = note.blocks.firstIndex(where: { $0.id == blockID }),
              note.blocks[index].kind == .checklist else { return }

        let current = note.blocks[index].indentLevel
        if offset > 0 {
            guard index > 0, note.blocks[index - 1].kind == .checklist else { return }
            let previousLevel = note.blocks[index - 1].indentLevel
            note.blocks[index].indentLevel = min(current + 1, min(previousLevel + 1, 4))
        } else {
            note.blocks[index].indentLevel = max(current - 1, 0)
        }
    }

    private var deleteAlertIsPresented: Binding<Bool> {
        Binding(
            get: { pendingDeleteID != nil },
            set: { isPresented in
                if !isPresented { pendingDeleteID = nil }
            }
        )
    }

    private func moveFocus(from blockID: UUID, by offset: Int) {
        guard let index = note.blocks.firstIndex(where: { $0.id == blockID }) else { return }
        var destination = index + offset
        while note.blocks.indices.contains(destination),
              note.blocks[destination].kind == .divider {
            destination += offset
        }
        guard note.blocks.indices.contains(destination) else { return }
        focusAtStartID = nil
        focusedBlockID = note.blocks[destination].id
    }

    private func confirmDelete() {
        guard let itemID = pendingDeleteID else {
            pendingDeleteID = nil
            return
        }
        guard let blockIndex = note.blocks.firstIndex(where: { block in
            block.todos.contains(where: { $0.id == itemID })
        }) else {
            pendingDeleteID = nil
            return
        }

        pendingDeleteID = nil
        deleteBlock(at: blockIndex)
    }

    private func backspaceAtStart(of blockID: UUID) {
        guard let index = note.blocks.firstIndex(where: { $0.id == blockID }) else { return }
        let currentText = note.blocks[index].text

        if note.blocks[index].kind != .text {
            note.blocks[index].kind = .text
            focusAtStartID = blockID
            focusedBlockID = blockID
            return
        }

        if index > 0, note.blocks[index - 1].kind == .text, !currentText.isEmpty {
            note.blocks[index - 1].text += currentText
            let previousID = note.blocks[index - 1].id
            note.blocks.remove(at: index)
            focusAtStartID = nil
            focusedBlockID = previousID
        } else if currentText.isEmpty, note.blocks.count > 1 {
            deleteBlock(at: index)
        }
    }

    private func turnIntoTodo(id: UUID) {
        guard let index = note.blocks.firstIndex(where: { $0.id == id }) else { return }
        let value = note.blocks[index].text
        note.blocks[index] = NoteBlock(
            id: id,
            kind: .checklist,
            todos: [TodoItem(text: value)]
        )
        focusedBlockID = id
    }

    private func turnIntoText(id: UUID) {
        guard let index = note.blocks.firstIndex(where: { $0.id == id }) else { return }
        let value = note.blocks[index].todos.first?.text ?? ""
        note.blocks[index] = NoteBlock(id: id, kind: .text, text: value)
        focusedBlockID = id
    }

    private func deleteBlock(id: UUID) {
        guard let index = note.blocks.firstIndex(where: { $0.id == id }) else { return }
        deleteBlock(at: index)
    }

    private func deleteBlock(at index: Int) {
        if note.blocks.count == 1 {
            let replacement = NoteBlock.text()
            note.blocks = [replacement]
            focusAtStartID = replacement.id
            focusedBlockID = replacement.id
            return
        }

        note.blocks.remove(at: index)
        let destination = min(index, note.blocks.count - 1)
        focusAtStartID = nil
        focusedBlockID = note.blocks[destination].id
    }
}

private final class StickyPanel: NSPanel {
    override var canBecomeKey: Bool { true }
    override var canBecomeMain: Bool { true }
}

private final class NoteWindowController: NSWindowController, NSWindowDelegate {
    let note: StickyNote
    weak var manager: NotesManager?
    private var frameUpdatesEnabled = false
    private var isAnimatingCollapse = false

    init(note: StickyNote, manager: NotesManager) {
        self.note = note
        self.manager = manager

        let height = note.isCollapsed ? 54.0 : max(note.height, 180)
        let frame = NSRect(x: note.x, y: note.y, width: max(note.width, 280), height: height)
        let panel = StickyPanel(
            contentRect: frame,
            styleMask: [.titled, .resizable, .fullSizeContentView],
            backing: .buffered,
            defer: false
        )
        panel.titleVisibility = .hidden
        panel.titlebarAppearsTransparent = true
        panel.isMovableByWindowBackground = false
        panel.isReleasedWhenClosed = false
        panel.backgroundColor = .clear
        panel.isOpaque = false
        panel.hasShadow = true
        panel.hidesOnDeactivate = false
        panel.minSize = NSSize(width: 280, height: note.isCollapsed ? 54 : 180)
        panel.maxSize = NSSize(width: 520, height: note.isCollapsed ? 54 : 700)
        panel.collectionBehavior = note.isPinned
            ? [.canJoinAllSpaces, .fullScreenAuxiliary, .stationary]
            : [.managed]
        panel.level = note.isPinned ? .floating : .normal
        panel.animationBehavior = .utilityWindow
        panel.standardWindowButton(.closeButton)?.isHidden = true
        panel.standardWindowButton(.miniaturizeButton)?.isHidden = true
        panel.standardWindowButton(.zoomButton)?.isHidden = true

        super.init(window: panel)
        panel.delegate = self

        let view = StickyNoteView(
            note: note,
            onNew: { [weak manager] in manager?.addNote() },
            onClose: { [weak manager] in manager?.deleteNote(id: note.id) },
            onDashboard: { [weak manager] in manager?.openDashboard() },
            onTogglePin: { [weak manager] in manager?.togglePin(id: note.id) },
            onToggleCollapse: { [weak manager] in manager?.toggleCollapse(id: note.id) }
        )
        panel.contentView = NSHostingView(rootView: view)
        panel.setFrame(frame, display: false)
        frameUpdatesEnabled = true
    }

    required init?(coder: NSCoder) { fatalError("init(coder:) has not been implemented") }

    func windowDidMove(_ notification: Notification) { captureFrame() }
    func windowDidResize(_ notification: Notification) { captureFrame() }

    private func captureFrame() {
        guard frameUpdatesEnabled, let frame = window?.frame else { return }
        if abs(note.x - frame.origin.x) > 0.25 { note.x = frame.origin.x }
        if abs(note.y - frame.origin.y) > 0.25 { note.y = frame.origin.y }
        if abs(note.width - frame.width) > 0.25 { note.width = frame.width }
        if !note.isCollapsed {
            if abs(note.height - frame.height) > 0.25 { note.height = frame.height }
            if abs(note.expandedHeight - frame.height) > 0.25 {
                note.expandedHeight = frame.height
            }
        }
    }

    func endEditing() {
        window?.makeFirstResponder(nil)
    }

    func applyPinState() {
        guard let window else { return }
        window.level = note.isPinned ? .floating : .normal
        window.collectionBehavior = note.isPinned
            ? [.canJoinAllSpaces, .fullScreenAuxiliary, .stationary]
            : [.managed]
        window.orderFrontRegardless()
    }

    func setCollapsed(_ collapsed: Bool) {
        guard let window,
              !isAnimatingCollapse,
              collapsed != note.isCollapsed else { return }

        isAnimatingCollapse = true
        frameUpdatesEnabled = false

        let currentFrame = window.frame
        let top = currentFrame.maxY
        var targetFrame = currentFrame

        if collapsed {
            note.height = max(currentFrame.height, 180)
            note.expandedHeight = note.height
            targetFrame.size.height = 54
            withAnimation(.easeOut(duration: 0.12)) {
                note.isCollapsed = true
            }
        } else {
            targetFrame.size.height = max(note.expandedHeight, 180)
        }
        targetFrame.origin.y = top - targetFrame.height

        // Keep permissive limits during the animation so AppKit does not snap
        // the frame before the animator receives its target.
        window.minSize = NSSize(width: 280, height: 54)
        window.maxSize = NSSize(width: 520, height: 700)

        NSAnimationContext.runAnimationGroup { context in
            context.duration = 0.20
            context.timingFunction = CAMediaTimingFunction(name: .easeInEaseOut)
            window.animator().setFrame(targetFrame, display: true)
        } completionHandler: { [weak self, weak window] in
            DispatchQueue.main.async {
                guard let self, let window else { return }
                if collapsed {
                    window.minSize = NSSize(width: 280, height: 54)
                    window.maxSize = NSSize(width: 520, height: 54)
                } else {
                    window.minSize = NSSize(width: 280, height: 180)
                    window.maxSize = NSSize(width: 520, height: 700)
                    withAnimation(.easeIn(duration: 0.12)) {
                        self.note.isCollapsed = false
                    }
                }
                self.frameUpdatesEnabled = true
                self.captureFrame()
                self.isAnimatingCollapse = false
            }
        }
    }
}

private struct DashboardNoteRow: View {
    @ObservedObject var note: StickyNote
    let onShow: () -> Void
    let onArchive: () -> Void
    let onRestore: () -> Void
    let onDeleteForever: () -> Void

    private var title: String {
        let noteTitle = note.title.trimmingCharacters(in: .whitespacesAndNewlines)
        if !noteTitle.isEmpty { return noteTitle }

        for block in note.blocks {
            if block.kind.isTextual {
                let trimmed = block.text.trimmingCharacters(in: .whitespacesAndNewlines)
                if !trimmed.isEmpty {
                    return trimmed.split(whereSeparator: \ .isNewline).first.map(String.init) ?? trimmed
                }
            } else if let item = block.todos.first(where: {
                !$0.text.trimmingCharacters(in: .whitespaces).isEmpty
            }) {
                return item.text
            }
        }
        return "Empty note"
    }

    private var detail: String {
        let tasks = note.blocks.flatMap(\.todos)
        let completed = tasks.filter(\.isDone).count
        if tasks.isEmpty { return "\(note.blocks.count) text block\(note.blocks.count == 1 ? "" : "s")" }
        return "\(completed) of \(tasks.count) tasks completed • \(note.blocks.count) block\(note.blocks.count == 1 ? "" : "s")"
    }

    private var noteIcon: String {
        let kinds = Set(note.blocks.map(\.kind))
        if kinds.count > 1 { return "square.stack.3d.up" }
        return kinds.first?.systemImage ?? "text.alignleft"
    }

    var body: some View {
        HStack(spacing: 13) {
            RoundedRectangle(cornerRadius: 8, style: .continuous)
                .fill(Color(hex: note.colorHex))
                .frame(width: 38, height: 38)
                .overlay {
                    Image(systemName: noteIcon)
                        .font(.system(size: 14, weight: .semibold))
                        .foregroundStyle(Color.black.opacity(0.55))
                }

            VStack(alignment: .leading, spacing: 3) {
                Text(title)
                    .font(.system(size: 14, weight: .semibold, design: .rounded))
                    .foregroundStyle(.primary)
                    .lineLimit(1)
                Text(detail)
                    .font(.system(size: 11, weight: .medium, design: .rounded))
                    .foregroundStyle(.secondary)
            }

            Spacer(minLength: 10)

            if note.isDeleted {
                Button("Restore", action: onRestore)
                    .buttonStyle(.borderedProminent)
                    .controlSize(.small)
                Button(action: onDeleteForever) {
                    Image(systemName: "trash")
                }
                .buttonStyle(.borderless)
                .foregroundStyle(.red)
                .help("Delete permanently")
            } else {
                Button("Show", action: onShow)
                    .buttonStyle(.bordered)
                    .controlSize(.small)
                Button(action: onArchive) {
                    Image(systemName: "trash")
                }
                .buttonStyle(.borderless)
                .foregroundStyle(.secondary)
                .help("Move to Recently Deleted")
            }
        }
        .padding(.horizontal, 14)
        .padding(.vertical, 11)
        .background(Color.primary.opacity(0.045))
        .clipShape(RoundedRectangle(cornerRadius: 12, style: .continuous))
    }
}

private struct DashboardView: View {
    @ObservedObject var manager: NotesManager
    @State private var selection = 0
    @State private var pendingPermanentDeleteID: UUID?

    private var displayedNotes: [StickyNote] {
        let filtered = manager.notes.filter { selection == 0 ? !$0.isDeleted : $0.isDeleted }
        guard selection == 1 else { return filtered }
        return filtered.sorted { ($0.deletedAt ?? .distantPast) > ($1.deletedAt ?? .distantPast) }
    }

    var body: some View {
        VStack(spacing: 16) {
            HStack(spacing: 12) {
                Image(systemName: "square.stack.3d.up.fill")
                    .font(.system(size: 24, weight: .semibold))
                    .foregroundStyle(Color.accentColor)
                VStack(alignment: .leading, spacing: 1) {
                    Text("Floaties")
                        .font(.system(size: 22, weight: .bold, design: .rounded))
                    Text("All your notes in one place")
                        .font(.system(size: 12, weight: .medium, design: .rounded))
                        .foregroundStyle(.secondary)
                }
                Spacer()
                Button {
                    manager.addNote()
                } label: {
                    Label("New note", systemImage: "plus")
                }
                .buttonStyle(.bordered)
            }

            Picker("Notes", selection: $selection) {
                Text("Notes (\(manager.notes.filter { !$0.isDeleted }.count))").tag(0)
                Text("Recently Deleted (\(manager.notes.filter(\.isDeleted).count))").tag(1)
            }
            .pickerStyle(.segmented)
            .labelsHidden()

            if displayedNotes.isEmpty {
                VStack(spacing: 9) {
                    Image(systemName: selection == 0 ? "note.text" : "trash")
                        .font(.system(size: 30, weight: .light))
                        .foregroundStyle(.secondary)
                    Text(selection == 0 ? "No notes yet" : "Recently Deleted is empty")
                        .font(.system(size: 14, weight: .semibold, design: .rounded))
                        .foregroundStyle(.secondary)
                }
                .frame(maxWidth: .infinity, maxHeight: .infinity)
            } else {
                ScrollView {
                    LazyVStack(spacing: 9) {
                        ForEach(displayedNotes) { note in
                            DashboardNoteRow(
                                note: note,
                                onShow: { manager.showNote(id: note.id) },
                                onArchive: { manager.deleteNote(id: note.id) },
                                onRestore: { manager.restoreNote(id: note.id) },
                                onDeleteForever: { pendingPermanentDeleteID = note.id }
                            )
                        }
                    }
                }
            }
        }
        .padding(22)
        .frame(minWidth: 520, minHeight: 430)
        .alert("Delete this note permanently?", isPresented: permanentDeleteAlertIsPresented) {
            Button("Cancel", role: .cancel) { pendingPermanentDeleteID = nil }
                .keyboardShortcut(.cancelAction)
            Button("Delete Forever", role: .destructive) {
                if let id = pendingPermanentDeleteID { manager.permanentlyDeleteNote(id: id) }
                pendingPermanentDeleteID = nil
            }
            .keyboardShortcut(.defaultAction)
        } message: {
            Text("This note cannot be restored after permanent deletion.")
        }
    }

    private var permanentDeleteAlertIsPresented: Binding<Bool> {
        Binding(
            get: { pendingPermanentDeleteID != nil },
            set: { if !$0 { pendingPermanentDeleteID = nil } }
        )
    }
}

private final class NotesManager: ObservableObject {
    @Published private(set) var notes: [StickyNote] = []
    private var controllers: [UUID: NoteWindowController] = [:]
    private var dashboardController: NSWindowController?
    private var saveWorkItem: DispatchWorkItem?
    private var hidden = false

    private lazy var storageURL: URL = {
        let base = FileManager.default.urls(for: .applicationSupportDirectory, in: .userDomainMask)[0]
        let directory = base.appendingPathComponent(appName, isDirectory: true)
        try? FileManager.default.createDirectory(at: directory, withIntermediateDirectories: true)
        return directory.appendingPathComponent("notes.json")
    }()

    private lazy var backupURL: URL = {
        storageURL.deletingLastPathComponent().appendingPathComponent("notes.backup.json")
    }()

    init() {
        load()
    }

    func start() {
        if notes.isEmpty {
            addNote()
        } else {
            notes.filter { !$0.isDeleted }.forEach(showWindow)
            scheduleSave()
        }
    }

    func addNote() {
        let screen = NSScreen.main?.visibleFrame ?? NSRect(x: 0, y: 0, width: 1200, height: 800)
        let width = 320.0
        let height = 300.0
        let activeCount = notes.filter { !$0.isDeleted }.count
        let offset = Double(activeCount % 8) * 20
        let note = StickyNote(
            colorHex: PaletteColor.all[activeCount % PaletteColor.all.count].hex,
            x: screen.maxX - width - 28 - offset,
            y: screen.maxY - height - 28 - offset,
            width: width,
            height: height,
            expandedHeight: height
        )
        attach(note)
        notes.append(note)
        showWindow(note)
        scheduleSave()
        hidden = false
    }

    func deleteNote(id: UUID) {
        guard let note = notes.first(where: { $0.id == id }), !note.isDeleted else { return }
        controllers[id]?.close()
        controllers.removeValue(forKey: id)
        objectWillChange.send()
        note.isDeleted = true
        note.deletedAt = Date()
        scheduleSave()
    }

    func restoreNote(id: UUID) {
        guard let note = notes.first(where: { $0.id == id }), note.isDeleted else { return }
        objectWillChange.send()
        note.isDeleted = false
        note.deletedAt = nil
        showWindow(note)
        scheduleSave()
        hidden = false
    }

    func permanentlyDeleteNote(id: UUID) {
        controllers[id]?.close()
        controllers.removeValue(forKey: id)
        notes.removeAll { $0.id == id }
        scheduleSave()
    }

    func showNote(id: UUID) {
        guard let note = notes.first(where: { $0.id == id }), !note.isDeleted else { return }
        if controllers[id] == nil { showWindow(note) }
        controllers[id]?.window?.orderFrontRegardless()
        hidden = false
    }

    func openDashboard() {
        if dashboardController == nil {
            let window = NSWindow(
                contentRect: NSRect(x: 0, y: 0, width: 580, height: 520),
                styleMask: [.titled, .closable, .miniaturizable, .resizable],
                backing: .buffered,
                defer: false
            )
            window.title = "Floaties Dashboard"
            window.titlebarAppearsTransparent = true
            window.isReleasedWhenClosed = false
            window.minSize = NSSize(width: 520, height: 430)
            window.center()
            window.contentView = NSHostingView(rootView: DashboardView(manager: self))
            dashboardController = NSWindowController(window: window)
        }
        NSApp.activate(ignoringOtherApps: true)
        dashboardController?.showWindow(nil)
        dashboardController?.window?.makeKeyAndOrderFront(nil)
    }

    func togglePin(id: UUID) {
        guard let note = notes.first(where: { $0.id == id }) else { return }
        note.isPinned.toggle()
        controllers[id]?.applyPinState()
    }

    func toggleCollapse(id: UUID) {
        guard let note = notes.first(where: { $0.id == id }) else { return }
        controllers[id]?.setCollapsed(!note.isCollapsed)
    }

    func toggleVisibility() {
        hidden.toggle()
        for controller in controllers.values {
            if hidden {
                controller.window?.orderOut(nil)
            } else {
                controller.window?.orderFrontRegardless()
            }
        }
    }

    func bringForward() {
        hidden = false
        controllers.values.forEach { $0.window?.orderFrontRegardless() }
    }

    func endEditing() {
        controllers.values.forEach { $0.endEditing() }
        dashboardController?.window?.makeFirstResponder(nil)
    }

    func saveNow() {
        saveWorkItem?.cancel()
        do {
            let data = try JSONEncoder().encode(notes)
            if FileManager.default.fileExists(atPath: storageURL.path) {
                try? FileManager.default.removeItem(at: backupURL)
                try? FileManager.default.copyItem(at: storageURL, to: backupURL)
            }
            try data.write(to: storageURL, options: .atomic)
        } catch {
            NSLog("Floaties could not save notes: \(error)")
        }
    }

    private func showWindow(_ note: StickyNote) {
        let controller = NoteWindowController(note: note, manager: self)
        controllers[note.id] = controller
        controller.showWindow(nil)
        controller.window?.orderFrontRegardless()
    }

    private func attach(_ note: StickyNote) {
        note.onChange = { [weak self] in self?.scheduleSave() }
    }

    private func scheduleSave() {
        saveWorkItem?.cancel()
        let work = DispatchWorkItem { [weak self] in self?.saveNow() }
        saveWorkItem = work
        DispatchQueue.main.asyncAfter(deadline: .now() + 0.45, execute: work)
    }

    private func load() {
        for url in [storageURL, backupURL] {
            guard let data = try? Data(contentsOf: url),
                  let decoded = try? JSONDecoder().decode([StickyNote].self, from: data) else { continue }
            notes = decoded
            notes.forEach(attach)
            if url == storageURL, !FileManager.default.fileExists(atPath: backupURL.path) {
                try? FileManager.default.copyItem(at: storageURL, to: backupURL)
            }
            return
        }
    }
}

private final class AppDelegate: NSObject, NSApplicationDelegate {
    private let manager = NotesManager()
    private var statusItem: NSStatusItem!

    func applicationDidFinishLaunching(_ notification: Notification) {
        NSApp.setActivationPolicy(.accessory)
        setupStatusItem()
        observeSystemLifecycle()
        manager.start()
        if CommandLine.arguments.contains("--dashboard") {
            manager.openDashboard()
        }
    }

    func applicationWillTerminate(_ notification: Notification) {
        manager.saveNow()
    }

    func applicationDidResignActive(_ notification: Notification) {
        manager.endEditing()
        manager.saveNow()
    }

    private func observeSystemLifecycle() {
        let workspaceNotifications = NSWorkspace.shared.notificationCenter
        workspaceNotifications.addObserver(
            self,
            selector: #selector(systemWillSleepOrPowerOff),
            name: NSWorkspace.willSleepNotification,
            object: nil
        )
        workspaceNotifications.addObserver(
            self,
            selector: #selector(systemWillSleepOrPowerOff),
            name: NSWorkspace.willPowerOffNotification,
            object: nil
        )
    }

    @objc private func systemWillSleepOrPowerOff() {
        manager.saveNow()
    }

    private func setupStatusItem() {
        statusItem = NSStatusBar.system.statusItem(withLength: NSStatusItem.squareLength)
        statusItem.button?.image = NSImage(systemSymbolName: "note.text", accessibilityDescription: "Floaties")
        statusItem.button?.toolTip = "Floaties"

        let menu = NSMenu()
        menu.addItem(item("New note", action: #selector(newNote), key: "n"))
        menu.addItem(.separator())
        menu.addItem(item("Notes Dashboard", action: #selector(openDashboard), key: "d"))
        menu.addItem(.separator())
        menu.addItem(item("Show or hide notes", action: #selector(toggleNotes), key: "h", modifiers: [.command, .shift]))
        menu.addItem(item("Bring notes forward", action: #selector(bringForward), key: "f", modifiers: [.command, .shift]))
        menu.addItem(.separator())
        menu.addItem(item("Quit Floaties", action: #selector(quit), key: "q"))
        statusItem.menu = menu
    }

    private func item(_ title: String, action: Selector, key: String,
                      modifiers: NSEvent.ModifierFlags = [.command]) -> NSMenuItem {
        let item = NSMenuItem(title: title, action: action, keyEquivalent: key)
        item.target = self
        item.keyEquivalentModifierMask = modifiers
        return item
    }

    @objc private func newNote() { manager.addNote() }
    @objc private func openDashboard() { manager.openDashboard() }
    @objc private func toggleNotes() { manager.toggleVisibility() }
    @objc private func bringForward() { manager.bringForward() }
    @objc private func quit() { NSApp.terminate(nil) }
}

private let application = NSApplication.shared
private let delegate = AppDelegate()
application.delegate = delegate
application.run()
