import AppKit
import ServiceManagement

public class StatusBarItemController: NSObject {
    public static let shared = StatusBarItemController()
    
    private var statusItem: NSStatusItem?
    
    public func setupStatusBar() {
        statusItem = NSStatusBar.system.statusItem(withLength: NSStatusItem.variableLength)
        
        guard let button = statusItem?.button else { return }
        
        // Clean, crisp vector menu bar icon
        button.image = Self.createMenuBarIcon()
        button.imagePosition = .imageOnly
        button.toolTip = "EasyFinder - Click to view programs or press ⌥Space"
        
        button.target = self
        button.action = #selector(statusBarButtonClicked(_:))
        button.sendAction(on: [.leftMouseUp, .rightMouseUp])
    }
    
    /// Creates a sleek, sharp 18x18 template keycap icon with ⌥ symbol
    private static func createMenuBarIcon() -> NSImage {
        let size = NSSize(width: 18, height: 18)
        let img = NSImage(size: size, flipped: false) { rect in
            // Outer rounded keycap border
            let boxRect = NSRect(x: 1.5, y: 1.5, width: 15, height: 15)
            let path = NSBezierPath(roundedRect: boxRect, xRadius: 3.5, yRadius: 3.5)
            path.lineWidth = 1.3
            NSColor.black.setStroke()
            path.stroke()
            
            // Option symbol ⌥ inside
            let str = "⌥" as NSString
            let font = NSFont.systemFont(ofSize: 10.5, weight: .bold)
            let attrs: [NSAttributedString.Key: Any] = [
                .font: font,
                .foregroundColor: NSColor.black
            ]
            let strSize = str.size(withAttributes: attrs)
            let strRect = NSRect(
                x: (rect.width - strSize.width) / 2,
                y: (rect.height - strSize.height) / 2 - 0.5,
                width: strSize.width,
                height: strSize.height
            )
            str.draw(in: strRect, withAttributes: attrs)
            return true
        }
        img.isTemplate = true
        return img
    }
    
    @objc private func statusBarButtonClicked(_ sender: NSStatusBarButton) {
        let event = NSApp.currentEvent
        
        // If right-clicked or control-clicked: show context menu
        if event?.type == .rightMouseUp || (event?.modifierFlags.contains(.control) == true) {
            let menu = buildContextMenu()
            statusItem?.menu = menu
            statusItem?.button?.performClick(nil)
            statusItem?.menu = nil // Clear so left clicks trigger button action
        } else {
            // Left click: toggle the launcher HUD anchored directly under this menu bar button!
            HUDController.shared.toggle(anchoredTo: sender)
        }
    }
    
    /// Builds a context menu that also displays all available programs with their icons and hotkeys
    private func buildContextMenu() -> NSMenu {
        let menu = NSMenu()
        
        // Header
        let titleItem = NSMenuItem(title: "EasyFinder Programs (⌥Space)", action: nil, keyEquivalent: "")
        titleItem.isEnabled = false
        menu.addItem(titleItem)
        menu.addItem(NSMenuItem.separator())
        
        // List each configured program with its number key and icon
        for key in ConfigManager.shared.slotKeys {
            if let shortcut = ConfigManager.shared.shortcuts.first(where: { $0.key == key }), !shortcut.path.isEmpty {
                let item = NSMenuItem(
                    title: "\(key).  \(shortcut.name)",
                    action: #selector(launchAppFromMenu(_:)),
                    keyEquivalent: key
                )
                item.keyEquivalentModifierMask = []
                item.target = self
                item.representedObject = shortcut
                
                // Small app icon in menu
                let iconCopy = shortcut.icon.copy() as? NSImage ?? shortcut.icon
                iconCopy.size = NSSize(width: 16, height: 16)
                item.image = iconCopy
                
                menu.addItem(item)
            }
        }
        
        menu.addItem(NSMenuItem.separator())
        
        let prefItem = NSMenuItem(title: "Preferences...", action: #selector(openPreferences), keyEquivalent: ",")
        prefItem.target = self
        menu.addItem(prefItem)
        
        let loginItem = NSMenuItem(title: "Launch at Login", action: #selector(toggleLaunchAtLogin(_:)), keyEquivalent: "")
        loginItem.target = self
        loginItem.state = isLaunchAtLoginEnabled() ? .on : .off
        menu.addItem(loginItem)
        
        menu.addItem(NSMenuItem.separator())
        
        let quitItem = NSMenuItem(title: "Quit EasyFinder", action: #selector(quitApp), keyEquivalent: "q")
        quitItem.target = self
        menu.addItem(quitItem)
        
        return menu
    }
    
    @objc private func launchAppFromMenu(_ sender: NSMenuItem) {
        if let shortcut = sender.representedObject as? AppShortcut {
            AppLauncher.shared.launch(shortcut: shortcut)
        }
    }
    
    @objc public func openPreferences() {
        SettingsWindowController.shared.showPreferences()
    }
    
    @objc private func toggleLaunchAtLogin(_ sender: NSMenuItem) {
        if #available(macOS 13.0, *) {
            do {
                if SMAppService.mainApp.status == .enabled {
                    try SMAppService.mainApp.unregister()
                    sender.state = .off
                } else {
                    try SMAppService.mainApp.register()
                    sender.state = .on
                }
            } catch {
                print("[EasyFinder] Failed to toggle launch at login: \(error.localizedDescription)")
            }
        }
    }
    
    private func isLaunchAtLoginEnabled() -> Bool {
        if #available(macOS 13.0, *) {
            return SMAppService.mainApp.status == .enabled
        }
        return false
    }
    
    @objc private func quitApp() {
        NSApp.terminate(nil)
    }
}
