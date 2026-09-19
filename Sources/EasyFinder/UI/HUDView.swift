import AppKit
import UniformTypeIdentifiers

public class HUDItemView: NSView, NSDraggingSource {
    public static let slotDragType = NSPasteboard.PasteboardType("com.lukejung.EasyFinder.slotDrag")
    
    public let slotKey: String
    public var shortcut: AppShortcut?
    public var onLaunch: ((AppShortcut) -> Void)?
    public var onPickApp: ((String) -> Void)?
    
    private let keyBadge = NSTextField(labelWithString: "")
    private let iconView = NSImageView()
    private let titleLabel = NSTextField(labelWithString: "")
    private let gripView = NSImageView()
    private let browseButton = NSButton()
    
    private var isHovered: Bool = false
    private var isSelected: Bool = false
    private var isDragTarget: Bool = false
    private var trackingArea: NSTrackingArea?
    private var mouseDownPoint: NSPoint?
    
    public init(slotKey: String, shortcut: AppShortcut?) {
        self.slotKey = slotKey
        self.shortcut = shortcut
        super.init(frame: .zero)
        
        setupViews()
        registerForDraggedTypes([Self.slotDragType, .fileURL])
    }
    
    required init?(coder: NSCoder) {
        fatalError("init(coder:) has not been implemented")
    }
    
    private func setupViews() {
        wantsLayer = true
        layer?.cornerRadius = 8
        layer?.masksToBounds = true
        
        // Keycap badge
        keyBadge.stringValue = slotKey
        keyBadge.font = NSFont.monospacedDigitSystemFont(ofSize: 12, weight: .bold)
        keyBadge.alignment = .center
        keyBadge.textColor = .labelColor
        keyBadge.wantsLayer = true
        keyBadge.layer?.cornerRadius = 5
        keyBadge.layer?.backgroundColor = NSColor.secondaryLabelColor.withAlphaComponent(0.18).cgColor
        keyBadge.layer?.borderWidth = 1
        keyBadge.layer?.borderColor = NSColor.white.withAlphaComponent(0.15).cgColor
        keyBadge.translatesAutoresizingMaskIntoConstraints = false
        
        // App icon
        iconView.imageScaling = .scaleProportionallyUpOrDown
        iconView.translatesAutoresizingMaskIntoConstraints = false
        
        // App title
        titleLabel.font = NSFont.systemFont(ofSize: 12, weight: .medium)
        titleLabel.textColor = .labelColor
        titleLabel.lineBreakMode = .byTruncatingTail
        titleLabel.translatesAutoresizingMaskIntoConstraints = false
        
        // Drag Grip Handle (appears on hover)
        if let gripImg = NSImage(systemSymbolName: "line.3.horizontal", accessibilityDescription: "Drag to reorder") {
            gripView.image = gripImg
            gripView.contentTintColor = .tertiaryLabelColor
        }
        gripView.translatesAutoresizingMaskIntoConstraints = false
        gripView.isHidden = true
        
        // Browse / Choose App button
        browseButton.bezelStyle = .inline
        browseButton.isBordered = false
        browseButton.image = NSImage(systemSymbolName: "ellipsis.circle", accessibilityDescription: "Choose Application")
        browseButton.contentTintColor = .secondaryLabelColor
        browseButton.target = self
        browseButton.action = #selector(browseClicked)
        browseButton.translatesAutoresizingMaskIntoConstraints = false
        browseButton.toolTip = "Choose application for slot \(slotKey)"
        browseButton.isHidden = true
        
        addSubview(keyBadge)
        addSubview(iconView)
        addSubview(titleLabel)
        addSubview(gripView)
        addSubview(browseButton)
        
        NSLayoutConstraint.activate([
            keyBadge.leadingAnchor.constraint(equalTo: leadingAnchor, constant: 6),
            keyBadge.centerYAnchor.constraint(equalTo: centerYAnchor),
            keyBadge.widthAnchor.constraint(equalToConstant: 22),
            keyBadge.heightAnchor.constraint(equalToConstant: 22),
            
            iconView.leadingAnchor.constraint(equalTo: keyBadge.trailingAnchor, constant: 8),
            iconView.centerYAnchor.constraint(equalTo: centerYAnchor),
            iconView.widthAnchor.constraint(equalToConstant: 22),
            iconView.heightAnchor.constraint(equalToConstant: 22),
            
            gripView.trailingAnchor.constraint(equalTo: trailingAnchor, constant: -6),
            gripView.centerYAnchor.constraint(equalTo: centerYAnchor),
            gripView.widthAnchor.constraint(equalToConstant: 14),
            gripView.heightAnchor.constraint(equalToConstant: 14),
            
            browseButton.trailingAnchor.constraint(equalTo: gripView.leadingAnchor, constant: -4),
            browseButton.centerYAnchor.constraint(equalTo: centerYAnchor),
            browseButton.widthAnchor.constraint(equalToConstant: 18),
            browseButton.heightAnchor.constraint(equalToConstant: 18),
            
            titleLabel.leadingAnchor.constraint(equalTo: iconView.trailingAnchor, constant: 8),
            titleLabel.trailingAnchor.constraint(equalTo: browseButton.leadingAnchor, constant: -4),
            titleLabel.centerYAnchor.constraint(equalTo: centerYAnchor),
            
            heightAnchor.constraint(equalToConstant: 32)
        ])
        
        updateData(shortcut: shortcut)
    }
    
    public func updateData(shortcut: AppShortcut?) {
        self.shortcut = shortcut
        if let s = shortcut, !s.path.isEmpty {
            titleLabel.stringValue = s.name
            titleLabel.textColor = .labelColor
            iconView.image = s.icon
            iconView.alphaValue = 1.0
        } else {
            titleLabel.stringValue = "Empty (Drop App)"
            titleLabel.textColor = .tertiaryLabelColor
            iconView.image = NSImage(systemSymbolName: "plus.app", accessibilityDescription: "Add")
            iconView.alphaValue = 0.5
        }
    }
    
    public override func updateTrackingAreas() {
        super.updateTrackingAreas()
        if let trackingArea = trackingArea {
            removeTrackingArea(trackingArea)
        }
        let area = NSTrackingArea(
            rect: bounds,
            options: [.mouseEnteredAndExited, .activeAlways],
            owner: self,
            userInfo: nil
        )
        addTrackingArea(area)
        self.trackingArea = area
    }
    
    public override func mouseEntered(with event: NSEvent) {
        isHovered = true
        browseButton.isHidden = false
        gripView.isHidden = false
        updateAppearance()
    }
    
    public override func mouseExited(with event: NSEvent) {
        isHovered = false
        browseButton.isHidden = true
        gripView.isHidden = true
        updateAppearance()
    }
    
    public override func mouseDown(with event: NSEvent) {
        mouseDownPoint = convert(event.locationInWindow, from: nil)
    }
    
    public override func mouseUp(with event: NSEvent) {
        guard let startPoint = mouseDownPoint else { return }
        let currentPoint = convert(event.locationInWindow, from: nil)
        let distance = hypot(currentPoint.x - startPoint.x, currentPoint.y - startPoint.y)
        mouseDownPoint = nil
        
        if distance < 5 {
            let location = convert(event.locationInWindow, from: nil)
            if browseButton.frame.contains(location) {
                return
            }
            
            if let s = shortcut, !s.path.isEmpty {
                onLaunch?(s)
            } else {
                onPickApp?(slotKey)
            }
        }
    }
    
    public override func mouseDragged(with event: NSEvent) {
        guard let startPoint = mouseDownPoint else { return }
        guard let s = shortcut, !s.path.isEmpty else { return }
        
        let currentPoint = convert(event.locationInWindow, from: nil)
        let distance = hypot(currentPoint.x - startPoint.x, currentPoint.y - startPoint.y)
        if distance >= 5 {
            mouseDownPoint = nil
            startDraggingSession(with: event)
        }
    }
    
    private func startDraggingSession(with event: NSEvent) {
        let pasteboardItem = NSPasteboardItem()
        pasteboardItem.setString(slotKey, forType: Self.slotDragType)
        
        let draggingItem = NSDraggingItem(pasteboardWriter: pasteboardItem)
        
        // Snapshot for drag feedback
        let dragImage = NSImage(size: bounds.size, flipped: false) { [weak self] rect in
            guard let self = self else { return false }
            NSColor.controlAccentColor.withAlphaComponent(0.2).setFill()
            NSBezierPath(roundedRect: rect, xRadius: 8, yRadius: 8).fill()
            if let icon = self.shortcut?.icon {
                icon.draw(in: NSRect(x: 36, y: (rect.height - 22) / 2, width: 22, height: 22))
            }
            let nameStr = (self.shortcut?.name ?? "") as NSString
            nameStr.draw(at: NSPoint(x: 66, y: (rect.height - 14) / 2), withAttributes: [
                .font: NSFont.systemFont(ofSize: 12, weight: .semibold),
                .foregroundColor: NSColor.labelColor
            ])
            return true
        }
        draggingItem.setDraggingFrame(bounds, contents: dragImage)
        
        beginDraggingSession(with: [draggingItem], event: event, source: self)
    }
    
    // MARK: - NSDraggingSource
    public func draggingSession(_ session: NSDraggingSession, sourceOperationMaskFor context: NSDraggingContext) -> NSDragOperation {
        return .move
    }
    
    @objc private func browseClicked() {
        onPickApp?(slotKey)
    }
    
    public func setSelected(_ selected: Bool) {
        self.isSelected = selected
        updateAppearance()
    }
    
    private func updateAppearance() {
        if isDragTarget {
            layer?.backgroundColor = NSColor.controlAccentColor.withAlphaComponent(0.35).cgColor
            layer?.borderWidth = 1.5
            layer?.borderColor = NSColor.controlAccentColor.cgColor
        } else if isSelected {
            layer?.backgroundColor = NSColor.controlAccentColor.withAlphaComponent(0.25).cgColor
            layer?.borderWidth = 1
            layer?.borderColor = NSColor.controlAccentColor.withAlphaComponent(0.6).cgColor
            keyBadge.layer?.backgroundColor = NSColor.controlAccentColor.cgColor
            keyBadge.textColor = .white
        } else if isHovered {
            layer?.backgroundColor = NSColor.white.withAlphaComponent(0.12).cgColor
            layer?.borderWidth = 1
            layer?.borderColor = NSColor.white.withAlphaComponent(0.2).cgColor
            keyBadge.layer?.backgroundColor = NSColor.controlAccentColor.withAlphaComponent(0.7).cgColor
            keyBadge.textColor = .white
        } else {
            layer?.backgroundColor = NSColor.clear.cgColor
            layer?.borderWidth = 0
            keyBadge.layer?.backgroundColor = NSColor.secondaryLabelColor.withAlphaComponent(0.18).cgColor
            keyBadge.textColor = .labelColor
        }
    }
    
    // MARK: - Drag and Drop Handling
    public override func draggingEntered(_ sender: NSDraggingInfo) -> NSDragOperation {
        let pasteboard = sender.draggingPasteboard
        
        // Reordering internal slots
        if pasteboard.types?.contains(Self.slotDragType) == true {
            isDragTarget = true
            updateAppearance()
            return .move
        }
        
        // Dropping external .app file
        if let url = extractFileURL(from: sender) {
            if url.pathExtension == "app" || (try? url.resourceValues(forKeys: [.isApplicationKey]))?.isApplication == true {
                isDragTarget = true
                updateAppearance()
                return .copy
            }
        }
        return []
    }
    
    public override func draggingUpdated(_ sender: NSDraggingInfo) -> NSDragOperation {
        let pasteboard = sender.draggingPasteboard
        if pasteboard.types?.contains(Self.slotDragType) == true {
            return .move
        }
        return isDragTarget ? .copy : []
    }
    
    public override func draggingExited(_ sender: NSDraggingInfo?) {
        isDragTarget = false
        updateAppearance()
    }
    
    public override func performDragOperation(_ sender: NSDraggingInfo) -> Bool {
        isDragTarget = false
        updateAppearance()
        
        let pasteboard = sender.draggingPasteboard
        
        // Reorder slots
        if let sourceSlot = pasteboard.string(forType: Self.slotDragType) {
            ConfigManager.shared.moveOrSwapSlot(from: sourceSlot, to: slotKey)
            return true
        }
        
        // External file dropped
        if let url = extractFileURL(from: sender) {
            ConfigManager.shared.setApp(forSlot: slotKey, fileURL: url)
            return true
        }
        
        return false
    }
    
    private func extractFileURL(from sender: NSDraggingInfo) -> URL? {
        let pasteboard = sender.draggingPasteboard
        guard let items = pasteboard.readObjects(forClasses: [NSURL.self], options: nil) as? [URL],
              let first = items.first else {
            return nil
        }
        return first
    }
}

public class HUDContentView: NSVisualEffectView {
    public var onSelectShortcut: ((AppShortcut) -> Void)?
    public var onDismiss: (() -> Void)?
    
    private let topIconView = NSImageView()
    private let titleLabel = NSTextField(labelWithString: "EasyFinder")
    private let hintBadge = NSTextField(labelWithString: "⌥Space")
    private let settingsButton = NSButton()
    private let rowsStackView = NSStackView()
    private let footerLabel = NSTextField(labelWithString: "Press 1–9 • Drag to reorder • Drop app")
    
    private var itemViews: [HUDItemView] = []
    public private(set) var selectedIndex: Int = 0
    
    public override init(frame frameRect: NSRect) {
        super.init(frame: frameRect)
        setup()
    }
    
    required init?(coder: NSCoder) {
        fatalError("init(coder:) has not been implemented")
    }
    
    private func setup() {
        wantsLayer = true
        material = .popover
        state = .active
        blendingMode = .behindWindow
        layer?.cornerRadius = 14
        layer?.masksToBounds = true
        layer?.borderWidth = 1
        layer?.borderColor = NSColor.white.withAlphaComponent(0.2).cgColor
        
        // Top Icon
        if let icon = NSImage(systemSymbolName: "command.circle.fill", accessibilityDescription: "EasyFinder") {
            topIconView.image = icon
            topIconView.contentTintColor = .controlAccentColor
        }
        topIconView.translatesAutoresizingMaskIntoConstraints = false
        
        // Title
        titleLabel.font = NSFont.systemFont(ofSize: 12, weight: .bold)
        titleLabel.textColor = .labelColor
        titleLabel.translatesAutoresizingMaskIntoConstraints = false
        
        // Shortcut Hint
        hintBadge.font = NSFont.systemFont(ofSize: 10, weight: .semibold)
        hintBadge.textColor = .secondaryLabelColor
        hintBadge.alignment = .center
        hintBadge.wantsLayer = true
        hintBadge.layer?.cornerRadius = 3
        hintBadge.layer?.backgroundColor = NSColor.secondaryLabelColor.withAlphaComponent(0.12).cgColor
        hintBadge.translatesAutoresizingMaskIntoConstraints = false
        
        // Settings Gear Button
        settingsButton.bezelStyle = .inline
        settingsButton.isBordered = false
        settingsButton.image = NSImage(systemSymbolName: "gearshape", accessibilityDescription: "Settings")
        settingsButton.contentTintColor = .secondaryLabelColor
        settingsButton.target = self
        settingsButton.action = #selector(openPreferencesClicked)
        settingsButton.toolTip = "EasyFinder Preferences..."
        settingsButton.translatesAutoresizingMaskIntoConstraints = false
        
        let headerView = NSView()
        headerView.translatesAutoresizingMaskIntoConstraints = false
        headerView.addSubview(topIconView)
        headerView.addSubview(titleLabel)
        headerView.addSubview(hintBadge)
        headerView.addSubview(settingsButton)
        
        NSLayoutConstraint.activate([
            topIconView.leadingAnchor.constraint(equalTo: headerView.leadingAnchor, constant: 10),
            topIconView.centerYAnchor.constraint(equalTo: headerView.centerYAnchor),
            topIconView.widthAnchor.constraint(equalToConstant: 16),
            topIconView.heightAnchor.constraint(equalToConstant: 16),
            
            titleLabel.leadingAnchor.constraint(equalTo: topIconView.trailingAnchor, constant: 6),
            titleLabel.centerYAnchor.constraint(equalTo: headerView.centerYAnchor),
            
            settingsButton.trailingAnchor.constraint(equalTo: headerView.trailingAnchor, constant: -10),
            settingsButton.centerYAnchor.constraint(equalTo: headerView.centerYAnchor),
            settingsButton.widthAnchor.constraint(equalToConstant: 18),
            settingsButton.heightAnchor.constraint(equalToConstant: 18),
            
            hintBadge.trailingAnchor.constraint(equalTo: settingsButton.leadingAnchor, constant: -6),
            hintBadge.centerYAnchor.constraint(equalTo: headerView.centerYAnchor),
            hintBadge.widthAnchor.constraint(equalToConstant: 46),
            hintBadge.heightAnchor.constraint(equalToConstant: 18),
            
            headerView.heightAnchor.constraint(equalToConstant: 30)
        ])
        
        let divider1 = NSBox()
        divider1.boxType = .separator
        divider1.translatesAutoresizingMaskIntoConstraints = false
        
        // Rows Stack
        rowsStackView.orientation = .vertical
        rowsStackView.alignment = .leading
        rowsStackView.spacing = 3
        rowsStackView.translatesAutoresizingMaskIntoConstraints = false
        
        let divider2 = NSBox()
        divider2.boxType = .separator
        divider2.translatesAutoresizingMaskIntoConstraints = false
        
        // Footer
        footerLabel.font = NSFont.systemFont(ofSize: 9.5, weight: .regular)
        footerLabel.textColor = .secondaryLabelColor
        footerLabel.alignment = .center
        footerLabel.translatesAutoresizingMaskIntoConstraints = false
        
        addSubview(headerView)
        addSubview(divider1)
        addSubview(rowsStackView)
        addSubview(divider2)
        addSubview(footerLabel)
        
        NSLayoutConstraint.activate([
            headerView.topAnchor.constraint(equalTo: topAnchor, constant: 4),
            headerView.leadingAnchor.constraint(equalTo: leadingAnchor),
            headerView.trailingAnchor.constraint(equalTo: trailingAnchor),
            
            divider1.topAnchor.constraint(equalTo: headerView.bottomAnchor, constant: 2),
            divider1.leadingAnchor.constraint(equalTo: leadingAnchor),
            divider1.trailingAnchor.constraint(equalTo: trailingAnchor),
            
            rowsStackView.topAnchor.constraint(equalTo: divider1.bottomAnchor, constant: 4),
            rowsStackView.leadingAnchor.constraint(equalTo: leadingAnchor, constant: 6),
            rowsStackView.trailingAnchor.constraint(equalTo: trailingAnchor, constant: -6),
            
            divider2.topAnchor.constraint(equalTo: rowsStackView.bottomAnchor, constant: 4),
            divider2.leadingAnchor.constraint(equalTo: leadingAnchor),
            divider2.trailingAnchor.constraint(equalTo: trailingAnchor),
            
            footerLabel.topAnchor.constraint(equalTo: divider2.bottomAnchor, constant: 4),
            footerLabel.leadingAnchor.constraint(equalTo: leadingAnchor, constant: 8),
            footerLabel.trailingAnchor.constraint(equalTo: trailingAnchor, constant: -8),
            footerLabel.bottomAnchor.constraint(equalTo: bottomAnchor, constant: -6)
        ])
        
        reloadSlots()
        
        ConfigManager.shared.onShortcutsChanged = { [weak self] in
            DispatchQueue.main.async {
                self?.reloadSlots()
            }
        }
    }
    
    @objc private func openPreferencesClicked() {
        onDismiss?()
        SettingsWindowController.shared.showPreferences()
    }
    
    public func reloadSlots() {
        for view in rowsStackView.arrangedSubviews {
            rowsStackView.removeArrangedSubview(view)
            view.removeFromSuperview()
        }
        itemViews.removeAll()
        
        for key in ConfigManager.shared.slotKeys {
            let shortcut = ConfigManager.shared.shortcuts.first(where: { $0.key == key })
            let itemView = HUDItemView(slotKey: key, shortcut: shortcut)
            itemView.translatesAutoresizingMaskIntoConstraints = false
            
            itemView.onLaunch = { [weak self] shortcut in
                self?.onSelectShortcut?(shortcut)
            }
            
            itemView.onPickApp = { [weak self] slotKey in
                self?.pickApp(forSlot: slotKey)
            }
            
            rowsStackView.addArrangedSubview(itemView)
            itemView.widthAnchor.constraint(equalTo: rowsStackView.widthAnchor).isActive = true
            itemViews.append(itemView)
        }
        
        updateSelectionHighlight()
    }
    
    public func pickApp(forSlot slotKey: String) {
        let openPanel = NSOpenPanel()
        openPanel.title = "Select Application for Slot [ \(slotKey) ]"
        openPanel.prompt = "Assign to Slot \(slotKey)"
        openPanel.allowedContentTypes = [UTType.application]
        openPanel.allowsMultipleSelection = false
        openPanel.canChooseDirectories = false
        openPanel.canChooseFiles = true
        openPanel.directoryURL = URL(fileURLWithPath: "/Applications")
        
        NSApp.activate(ignoringOtherApps: true)
        
        if openPanel.runModal() == .OK, let url = openPanel.url {
            ConfigManager.shared.setApp(forSlot: slotKey, fileURL: url)
        }
    }
    
    public func selectNext() {
        guard !itemViews.isEmpty else { return }
        selectedIndex = (selectedIndex + 1) % itemViews.count
        updateSelectionHighlight()
    }
    
    public func selectPrevious() {
        guard !itemViews.isEmpty else { return }
        selectedIndex = (selectedIndex - 1 + itemViews.count) % itemViews.count
        updateSelectionHighlight()
    }
    
    public var selectedShortcut: AppShortcut? {
        guard selectedIndex >= 0 && selectedIndex < itemViews.count else { return nil }
        return itemViews[selectedIndex].shortcut
    }
    
    private func updateSelectionHighlight() {
        for (index, itemView) in itemViews.enumerated() {
            itemView.setSelected(index == selectedIndex)
        }
    }
}
