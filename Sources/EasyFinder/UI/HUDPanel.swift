import AppKit

public class HUDPanel: NSPanel {
    init(contentRect: NSRect) {
        super.init(
            contentRect: contentRect,
            styleMask: [.nonactivatingPanel, .fullSizeContentView, .borderless],
            backing: .buffered,
            defer: false
        )
        
        self.isFloatingPanel = true
        self.level = .floating
        self.collectionBehavior = [.canJoinAllSpaces, .fullScreenAuxiliary, .transient]
        self.isOpaque = false
        self.backgroundColor = .clear
        self.hasShadow = true
        self.titleVisibility = .hidden
        self.titlebarAppearsTransparent = true
        self.isMovableByWindowBackground = true
        self.animationBehavior = .utilityWindow
    }
    
    public override var canBecomeKey: Bool {
        return true
    }
    
    public override var canBecomeMain: Bool {
        return true
    }
}

public class HUDController: NSObject {
    public static let shared = HUDController()
    
    private var panel: HUDPanel?
    private var contentView: HUDContentView?
    private var localKeyMonitor: Any?
    
    private let panelWidth: CGFloat = 264
    private let panelHeight: CGFloat = 394
    
    private override init() {
        super.init()
        setupPanel()
    }
    
    private func setupPanel() {
        let frame = NSRect(x: 0, y: 0, width: panelWidth, height: panelHeight)
        let panel = HUDPanel(contentRect: frame)
        
        let hudContent = HUDContentView(frame: frame)
        hudContent.onSelectShortcut = { [weak self] shortcut in
            self?.launch(shortcut: shortcut)
        }
        hudContent.onDismiss = { [weak self] in
            self?.hide()
        }
        
        panel.contentView = hudContent
        self.contentView = hudContent
        self.panel = panel
        
        // Auto-dismiss when clicking outside
        NotificationCenter.default.addObserver(
            self,
            selector: #selector(windowDidResignKey),
            name: NSWindow.didResignKeyNotification,
            object: panel
        )
    }
    
    @objc private func windowDidResignKey() {
        hide()
    }
    
    public func toggle(anchoredTo view: NSView? = nil) {
        if let panel = panel, panel.isVisible {
            hide()
        } else {
            show(anchoredTo: view)
        }
    }
    
    public func show(anchoredTo anchorView: NSView? = nil) {
        guard let panel = panel, let contentView = contentView else { return }
        
        contentView.reloadSlots()
        
        // Determine target screen and position
        let targetScreen: NSScreen
        var targetX: CGFloat
        var targetY: CGFloat
        
        if let anchor = anchorView, let window = anchor.window {
            let anchorRect = window.convertToScreen(anchor.bounds)
            targetScreen = window.screen ?? NSScreen.main ?? NSScreen.screens[0]
            let screenRect = targetScreen.visibleFrame
            
            // Align horizontally centered with the menu bar button
            let midX = anchorRect.midX - panelWidth / 2
            targetX = max(screenRect.origin.x + 8, min(midX, screenRect.origin.x + screenRect.width - panelWidth - 8))
            targetY = screenRect.origin.y + screenRect.height - panelHeight - 4
        } else {
            let mouseLocation = NSEvent.mouseLocation
            targetScreen = NSScreen.screens.first { NSMouseInRect(mouseLocation, $0.frame, false) } ?? NSScreen.main ?? NSScreen.screens[0]
            let screenRect = targetScreen.visibleFrame
            
            targetX = screenRect.origin.x + (screenRect.width - panelWidth) / 2
            targetY = screenRect.origin.y + screenRect.height - panelHeight - 6
        }
        
        panel.setFrame(NSRect(x: targetX, y: targetY, width: panelWidth, height: panelHeight), display: true)
        panel.makeKeyAndOrderFront(nil)
        NSApp.activate(ignoringOtherApps: true)
        
        startKeyMonitor()
    }
    
    public func hide() {
        stopKeyMonitor()
        panel?.orderOut(nil)
    }
    
    private func launch(shortcut: AppShortcut) {
        hide()
        AppLauncher.shared.launch(shortcut: shortcut)
    }
    
    private func startKeyMonitor() {
        stopKeyMonitor()
        
        localKeyMonitor = NSEvent.addLocalMonitorForEvents(matching: .keyDown) { [weak self] event in
            guard let self = self, let contentView = self.contentView else { return event }
            
            // ESC key: Dismiss immediately
            if event.keyCode == 53 {
                self.hide()
                return nil
            }
            
            // Return / Enter key: Launch selected item
            if event.keyCode == 36 {
                if let selected = contentView.selectedShortcut, !selected.path.isEmpty {
                    self.launch(shortcut: selected)
                    return nil
                }
            }
            
            // Arrow Keys for navigation
            if event.keyCode == 126 { // Up arrow
                contentView.selectPrevious()
                return nil
            } else if event.keyCode == 125 { // Down arrow
                contentView.selectNext()
                return nil
            }
            
            // Direct Number Keys (1..9, 0)
            if let characters = event.charactersIgnoringModifiers, characters.count == 1 {
                let char = characters
                if ConfigManager.shared.slotKeys.contains(char) {
                    if let shortcut = ConfigManager.shared.shortcut(forKey: char) {
                        self.launch(shortcut: shortcut)
                        return nil
                    } else {
                        // Empty slot: open app picker for this number
                        contentView.pickApp(forSlot: char)
                        return nil
                    }
                }
            }
            
            return event
        }
    }
    
    private func stopKeyMonitor() {
        if let monitor = localKeyMonitor {
            NSEvent.removeMonitor(monitor)
            self.localKeyMonitor = nil
        }
    }
}
