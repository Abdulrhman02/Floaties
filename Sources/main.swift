import AppKit
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
}

private struct NoteBlock: Identifiable, Codable, Equatable {
    var id = UUID()
    var kind: NoteBlockKind
    var text = ""
    var todos: [TodoItem] = []

    static func text(_ value: String = "") -> NoteBlock {
        NoteBlock(kind: .text, text: value)
    }

    static func checklist(_ items: [TodoItem] = [TodoItem()]) -> NoteBlock {
        NoteBlock(kind: .checklist, todos: items)
    }
}

private final class StickyNote: ObservableObject, Codable, Identifiable {
    let id: UUID
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

    init(id: UUID = UUID(), text: String = "", todos: [TodoItem] = [], isChecklist: Bool = false,
         blocks: [NoteBlock]? = nil,
         colorHex: String = PaletteColor.all[0].hex, isPinned: Bool = true,
         isCollapsed: Bool = false, isDeleted: Bool = false, deletedAt: Date? = nil,
         x: Double, y: Double, width: Double = 320,
         height: Double = 300, expandedHeight: Double = 300) {
        self.id = id
        self.text = text
        self.todos = todos
        self.isChecklist = isChecklist
        self.blocks = blocks ?? (isChecklist ? [.checklist(todos)] : [.text(text)])
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
        case id, text, todos, isChecklist, blocks, colorHex, isPinned, isCollapsed, isDeleted, deletedAt
        case x, y, width, height, expandedHeight
    }

    required init(from decoder: Decoder) throws {
        let c = try decoder.container(keyedBy: CodingKeys.self)
        id = try c.decode(UUID.self, forKey: .id)
        let decodedText = try c.decodeIfPresent(String.self, forKey: .text) ?? ""
        let decodedTodos = try c.decodeIfPresent([TodoItem].self, forKey: .todos) ?? []
        let decodedIsChecklist = try c.decodeIfPresent(Bool.self, forKey: .isChecklist) ?? false
        text = decodedText
        todos = decodedTodos
        isChecklist = decodedIsChecklist
        blocks = try c.decodeIfPresent([NoteBlock].self, forKey: .blocks)
            ?? (decodedIsChecklist ? [NoteBlock.checklist(decodedTodos)] : [NoteBlock.text(decodedText)])
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

private final class NavigableTodoTextField: NSTextField {}

private struct TodoTextField: NSViewRepresentable {
    @Binding var text: String
    @Binding var focusedItemID: UUID?
    let itemID: UUID
    let isDone: Bool
    let onSubmit: () -> Void
    let onToggleDone: () -> Void
    let onMove: (Int) -> Void
    let onRequestDelete: () -> Void

    final class Coordinator: NSObject, NSTextFieldDelegate {
        var parent: TodoTextField

        init(parent: TodoTextField) {
            self.parent = parent
        }

        func controlTextDidBeginEditing(_ notification: Notification) {
            parent.focusedItemID = parent.itemID
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
                let textLength = (textView.string as NSString).length
                let cursorLocation = textView.selectedRange().location
                if cursorLocation < textLength {
                    parent.onToggleDone()
                } else {
                    parent.onSubmit()
                }
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
        field.placeholderString = "To-do"
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

        return field
    }

    func updateNSView(_ field: NavigableTodoTextField, context: Context) {
        context.coordinator.parent = self
        if field.stringValue != text {
            field.stringValue = text
        }
        field.textColor = NSColor.black.withAlphaComponent(isDone ? 0.46 : 0.78)

        if focusedItemID == itemID, field.currentEditor() == nil {
            DispatchQueue.main.async { [weak field] in
                guard let field, field.currentEditor() == nil else { return }
                field.window?.makeFirstResponder(field)
                if let editor = field.currentEditor() {
                    editor.selectedRange = NSRange(location: field.stringValue.utf16.count, length: 0)
                }
            }
        }
    }
}

private struct TodoRow: View {
    @Binding var item: TodoItem
    @Binding var focusedItemID: UUID?
    let onSubmit: () -> Void
    let onMove: (Int) -> Void
    let onRequestDelete: () -> Void

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
                focusedItemID: $focusedItemID,
                itemID: item.id,
                isDone: item.isDone,
                onSubmit: onSubmit,
                onToggleDone: { item.isDone.toggle() },
                onMove: onMove,
                onRequestDelete: onRequestDelete
            )

            Button(action: onRequestDelete) {
                Image(systemName: "xmark")
                    .font(.system(size: 9, weight: .bold))
                    .foregroundStyle(Color.black.opacity(0.35))
                    .frame(width: 20, height: 20)
            }
            .buttonStyle(.plain)
        }
        .padding(.vertical, 3)
    }
}

private struct TodoDropDelegate: DropDelegate {
    let targetID: UUID
    @Binding var items: [TodoItem]
    @Binding var draggedID: UUID?

    func dropEntered(info: DropInfo) {
        guard let draggedID,
              draggedID != targetID,
              let sourceIndex = items.firstIndex(where: { $0.id == draggedID }),
              let targetIndex = items.firstIndex(where: { $0.id == targetID }) else { return }

        withAnimation(.easeInOut(duration: 0.14)) {
            items.move(
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

private struct StickyNoteView: View {
    @ObservedObject var note: StickyNote
    @State private var focusedTodoID: UUID?
    @State private var pendingDeleteID: UUID?
    @State private var draggedTodoID: UUID?
    let onNew: (Bool) -> Void
    let onClose: () -> Void
    let onStack: () -> Void
    let onDashboard: () -> Void
    let onTogglePin: () -> Void
    let onToggleCollapse: () -> Void

    private var noteColor: Color { Color(hex: note.colorHex) }

    var body: some View {
        VStack(spacing: 0) {
            header
                .frame(height: 42)

            if !note.isCollapsed {
                Divider().overlay(Color.black.opacity(0.08))
                content
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
        HStack(spacing: 6) {
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

            Spacer(minLength: 2)

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
                Image(systemName: "paintpalette.fill")
            }
            .menuStyle(.borderlessButton)
            .menuIndicator(.hidden)
            .buttonStyle(HeaderButtonStyle())
            .frame(width: 25)
            .help("Choose color")

            Button(action: onStack) {
                Image(systemName: "square.stack.3d.up.fill")
            }
            .buttonStyle(HeaderButtonStyle())
            .help("Stack all notes")

            Button(action: onDashboard) {
                Image(systemName: "rectangle.grid.1x2.fill")
            }
            .buttonStyle(HeaderButtonStyle())
            .help("Open notes dashboard")

            Menu {
                Button("New note — start with text") { onNew(false) }
                Button("New note — start with checklist") { onNew(true) }
            } label: {
                Image(systemName: "plus")
            }
            .menuStyle(.borderlessButton)
            .menuIndicator(.hidden)
            .buttonStyle(HeaderButtonStyle())
            .frame(width: 25)
            .help("New note")

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
        .padding(.horizontal, 8)
        .contentShape(Rectangle())
    }

    private var content: some View {
        VStack(spacing: 0) {
            ScrollView {
                LazyVStack(spacing: 10) {
                    ForEach($note.blocks) { $block in
                        blockView(block: $block)
                    }
                }
                .padding(.horizontal, 10)
                .padding(.vertical, 10)
            }

            Divider().overlay(Color.black.opacity(0.07))

            HStack(spacing: 14) {
                Button {
                    note.blocks.append(.text())
                } label: {
                    Label("Text", systemImage: "text.alignleft")
                }
                Button {
                    note.blocks.append(.checklist())
                } label: {
                    Label("Checklist", systemImage: "checklist")
                }
            }
            .buttonStyle(.plain)
            .font(.system(size: 11, weight: .semibold, design: .rounded))
            .foregroundStyle(Color.black.opacity(0.5))
            .padding(.vertical, 9)
        }
    }

    @ViewBuilder private func blockView(block: Binding<NoteBlock>) -> some View {
        VStack(spacing: 5) {
            HStack(spacing: 5) {
                Image(systemName: block.wrappedValue.kind == .text ? "text.alignleft" : "checklist")
                Text(block.wrappedValue.kind == .text ? "TEXT" : "CHECKLIST")
                Spacer()
                if note.blocks.count > 1 {
                    Menu {
                        Button("Remove section", role: .destructive) {
                            removeBlock(id: block.wrappedValue.id)
                        }
                    } label: {
                        Image(systemName: "ellipsis")
                            .frame(width: 22, height: 18)
                    }
                    .menuStyle(.borderlessButton)
                    .menuIndicator(.hidden)
                    .frame(width: 22)
                }
            }
            .font(.system(size: 9, weight: .bold, design: .rounded))
            .foregroundStyle(Color.black.opacity(0.32))
            .padding(.horizontal, 9)
            .padding(.top, 7)

            if block.wrappedValue.kind == .text {
                TextEditor(text: block.text)
                    .font(.system(size: 16, weight: .medium, design: .rounded))
                    .foregroundStyle(Color.black.opacity(0.78))
                    .scrollContentBackground(.hidden)
                    .background(Color.clear)
                    .frame(minHeight: 86)
                    .padding(.horizontal, 5)
                    .padding(.bottom, 5)
            } else {
                LazyVStack(spacing: 1) {
                    ForEach(block.todos) { $item in
                        TodoRow(
                            item: $item,
                            focusedItemID: $focusedTodoID,
                            onSubmit: { insertTodo(in: block.wrappedValue.id, after: item.id) },
                            onMove: { moveFocus(in: block.wrappedValue.id, from: item.id, by: $0) },
                            onRequestDelete: { pendingDeleteID = item.id }
                        )
                        .contentShape(Rectangle())
                        .onDrag {
                            draggedTodoID = item.id
                            return NSItemProvider(object: item.id.uuidString as NSString)
                        }
                        .onDrop(
                            of: [UTType.text],
                            delegate: TodoDropDelegate(
                                targetID: item.id,
                                items: block.todos,
                                draggedID: $draggedTodoID
                            )
                        )
                    }
                }
                .padding(.horizontal, 8)

                Button {
                    appendTodo(in: block.wrappedValue.id)
                } label: {
                    Label("Add item", systemImage: "plus.circle.fill")
                        .font(.system(size: 11, weight: .semibold, design: .rounded))
                        .foregroundStyle(Color.black.opacity(0.46))
                }
                .buttonStyle(.plain)
                .padding(.bottom, 9)
            }
        }
        .background(Color.white.opacity(0.16))
        .clipShape(RoundedRectangle(cornerRadius: 11, style: .continuous))
    }

    private func insertTodo(in blockID: UUID, after itemID: UUID) {
        let newItem = TodoItem()
        guard let blockIndex = note.blocks.firstIndex(where: { $0.id == blockID }) else { return }
        if let index = note.blocks[blockIndex].todos.firstIndex(where: { $0.id == itemID }) {
            note.blocks[blockIndex].todos.insert(newItem, at: index + 1)
        } else {
            note.blocks[blockIndex].todos.append(newItem)
        }
        DispatchQueue.main.async {
            focusedTodoID = newItem.id
        }
    }

    private func appendTodo(in blockID: UUID) {
        guard let blockIndex = note.blocks.firstIndex(where: { $0.id == blockID }) else { return }
        let newItem = TodoItem()
        note.blocks[blockIndex].todos.append(newItem)
        DispatchQueue.main.async {
            focusedTodoID = newItem.id
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

    private func moveFocus(in blockID: UUID, from itemID: UUID, by offset: Int) {
        guard let block = note.blocks.first(where: { $0.id == blockID }),
              let index = block.todos.firstIndex(where: { $0.id == itemID }) else { return }
        let destination = min(max(index + offset, 0), block.todos.count - 1)
        focusedTodoID = block.todos[destination].id
    }

    private func confirmDelete() {
        guard let itemID = pendingDeleteID else {
            pendingDeleteID = nil
            return
        }
        guard let blockIndex = note.blocks.firstIndex(where: { block in
            block.todos.contains(where: { $0.id == itemID })
        }), let itemIndex = note.blocks[blockIndex].todos.firstIndex(where: { $0.id == itemID }) else {
            pendingDeleteID = nil
            return
        }

        note.blocks[blockIndex].todos.remove(at: itemIndex)
        pendingDeleteID = nil

        guard !note.blocks[blockIndex].todos.isEmpty else {
            focusedTodoID = nil
            return
        }
        let nextIndex = min(itemIndex, note.blocks[blockIndex].todos.count - 1)
        let nextID = note.blocks[blockIndex].todos[nextIndex].id
        DispatchQueue.main.async {
            focusedTodoID = nextID
        }
    }

    private func removeBlock(id: UUID) {
        guard note.blocks.count > 1 else { return }
        note.blocks.removeAll { $0.id == id }
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
        panel.minSize = NSSize(width: 280, height: 180)
        panel.maxSize = NSSize(width: 520, height: 700)
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
            onNew: { [weak manager] isChecklist in manager?.addNote(isChecklist: isChecklist) },
            onClose: { [weak manager] in manager?.deleteNote(id: note.id) },
            onStack: { [weak manager] in manager?.stackNotes() },
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
        note.x = frame.origin.x
        note.y = frame.origin.y
        note.width = frame.width
        if !note.isCollapsed {
            note.height = frame.height
            note.expandedHeight = frame.height
        }
    }

    func applyPinState() {
        guard let window else { return }
        window.level = note.isPinned ? .floating : .normal
        window.collectionBehavior = note.isPinned
            ? [.canJoinAllSpaces, .fullScreenAuxiliary, .stationary]
            : [.managed]
        window.orderFrontRegardless()
    }

    func applyCollapsedState() {
        guard let window else { return }
        var frame = window.frame
        if note.isCollapsed {
            note.expandedHeight = max(frame.height, 180)
            let top = frame.maxY
            frame.size.height = 54
            frame.origin.y = top - 54
            window.minSize = NSSize(width: 280, height: 54)
            window.maxSize = NSSize(width: 520, height: 54)
        } else {
            let top = frame.maxY
            frame.size.height = max(note.expandedHeight, 180)
            frame.origin.y = top - frame.height
            window.minSize = NSSize(width: 280, height: 180)
            window.maxSize = NSSize(width: 520, height: 700)
        }
        window.setFrame(frame, display: true, animate: true)
    }
}

private struct DashboardNoteRow: View {
    @ObservedObject var note: StickyNote
    let onShow: () -> Void
    let onArchive: () -> Void
    let onRestore: () -> Void
    let onDeleteForever: () -> Void

    private var title: String {
        for block in note.blocks {
            if block.kind == .text {
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
        if tasks.isEmpty { return "\(note.blocks.count) text section\(note.blocks.count == 1 ? "" : "s")" }
        return "\(completed) of \(tasks.count) tasks completed • \(note.blocks.count) section\(note.blocks.count == 1 ? "" : "s")"
    }

    private var noteIcon: String {
        let kinds = Set(note.blocks.map(\.kind))
        if kinds.count > 1 { return "square.stack.3d.up" }
        return kinds.first == .checklist ? "checklist" : "text.alignleft"
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
                Menu {
                    Button("Start with text") { manager.addNote(isChecklist: false) }
                    Button("Start with checklist") { manager.addNote(isChecklist: true) }
                } label: {
                    Label("New note", systemImage: "plus")
                }
                .menuStyle(.borderlessButton)
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
            addNote(isChecklist: false)
        } else {
            notes.filter { !$0.isDeleted }.forEach(showWindow)
            scheduleSave()
        }
    }

    func addNote(isChecklist: Bool) {
        let screen = NSScreen.main?.visibleFrame ?? NSRect(x: 0, y: 0, width: 1200, height: 800)
        let width = 320.0
        let height = 300.0
        let activeCount = notes.filter { !$0.isDeleted }.count
        let offset = Double(activeCount % 8) * 20
        let note = StickyNote(
            text: isChecklist ? "" : "Write something…",
            todos: isChecklist ? [TodoItem()] : [],
            isChecklist: isChecklist,
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
        note.isCollapsed.toggle()
        controllers[id]?.applyCollapsedState()
    }

    func stackNotes() {
        let screen = NSScreen.main?.visibleFrame ?? NSRect(x: 0, y: 0, width: 1200, height: 800)
        let baseWidth = controllers.values.compactMap { $0.window?.frame.width }.max() ?? 320
        for (index, note) in notes.filter({ !$0.isDeleted }).enumerated() {
            guard let window = controllers[note.id]?.window else { continue }
            let step = CGFloat(index % 9) * 16
            var frame = window.frame
            frame.origin.x = screen.maxX - baseWidth - 28 - step
            frame.origin.y = screen.maxY - frame.height - 28 - step
            window.setFrame(frame, display: true, animate: true)
            window.orderFrontRegardless()
        }
        hidden = false
        scheduleSave()
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
        DispatchQueue.main.asyncAfter(deadline: .now() + 0.12, execute: work)
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
        menu.addItem(item("New text note", action: #selector(newTextNote), key: "n"))
        let checklist = item("New checklist", action: #selector(newChecklist), key: "N")
        checklist.keyEquivalentModifierMask = [.command, .shift]
        menu.addItem(checklist)
        menu.addItem(.separator())
        menu.addItem(item("Notes Dashboard", action: #selector(openDashboard), key: "d"))
        menu.addItem(.separator())
        menu.addItem(item("Stack notes", action: #selector(stackNotes), key: "s", modifiers: [.command, .shift]))
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

    @objc private func newTextNote() { manager.addNote(isChecklist: false) }
    @objc private func newChecklist() { manager.addNote(isChecklist: true) }
    @objc private func openDashboard() { manager.openDashboard() }
    @objc private func stackNotes() { manager.stackNotes() }
    @objc private func toggleNotes() { manager.toggleVisibility() }
    @objc private func bringForward() { manager.bringForward() }
    @objc private func quit() { NSApp.terminate(nil) }
}

private let application = NSApplication.shared
private let delegate = AppDelegate()
application.delegate = delegate
application.run()
