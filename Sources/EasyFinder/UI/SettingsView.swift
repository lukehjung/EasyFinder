import AppKit
import UniformTypeIdentifiers

public class SettingsWindowController: NSWindowController, NSTableViewDataSource, NSTableViewDelegate {
    public static let shared = SettingsWindowController()
    
    private let tableView = NSTableView()
    private let resetButton = NSButton()
    
    public init() {
        let window = NSWindow(
            contentRect: NSRect(x: 0, y: 0, width: 520, height: 420),
            styleMask: [.titled, .closable, .miniaturizable],
            backing: .buffered,
            defer: false
        )
        window.title = "EasyFinder Slots & Hotkeys"
        window.center()
        
        super.init(window: window)
        setupUI()
    }
    
    required init?(coder: NSCoder) {
        fatalError("init(coder:) has not been implemented")
    }
    
    private func setupUI() {
        guard let contentView = window?.contentView else { return }
        
        let headerLabel = NSTextField(labelWithString: "EasyFinder Numbered Slots")
        headerLabel.font = NSFont.systemFont(ofSize: 15, weight: .bold)
        headerLabel.translatesAutoresizingMaskIntoConstraints = false
        
        let subLabel = NSTextField(labelWithString: "Press ⌥Space, then press a number (1–9, 0) to launch. Drag apps to change.")
        subLabel.font = NSFont.systemFont(ofSize: 12)
        subLabel.textColor = .secondaryLabelColor
        subLabel.translatesAutoresizingMaskIntoConstraints = false
        
        // Table Columns
        let colKey = NSTableColumn(identifier: NSUserInterfaceItemIdentifier("Key"))
        colKey.title = "Slot"
        colKey.width = 45
        
        let colApp = NSTableColumn(identifier: NSUserInterfaceItemIdentifier("App"))
        colApp.title = "Application"
        colApp.width = 300
        
        let colAction = NSTableColumn(identifier: NSUserInterfaceItemIdentifier("Action"))
        colAction.title = "Action"
        colAction.width = 120
        
        tableView.addTableColumn(colKey)
        tableView.addTableColumn(colApp)
        tableView.addTableColumn(colAction)
        tableView.dataSource = self
        tableView.delegate = self
        tableView.usesAlternatingRowBackgroundColors = true
        tableView.rowHeight = 32
        
        let scrollTable = NSScrollView()
        scrollTable.documentView = tableView
        scrollTable.hasVerticalScroller = true
        scrollTable.translatesAutoresizingMaskIntoConstraints = false
        
        resetButton.title = "Reset to Defaults"
        resetButton.bezelStyle = .rounded
        resetButton.target = self
        resetButton.action = #selector(resetDefaultsClicked)
        resetButton.translatesAutoresizingMaskIntoConstraints = false
        
        contentView.addSubview(headerLabel)
        contentView.addSubview(subLabel)
        contentView.addSubview(scrollTable)
        contentView.addSubview(resetButton)
        
        NSLayoutConstraint.activate([
            headerLabel.topAnchor.constraint(equalTo: contentView.topAnchor, constant: 16),
            headerLabel.leadingAnchor.constraint(equalTo: contentView.leadingAnchor, constant: 20),
            
            subLabel.topAnchor.constraint(equalTo: headerLabel.bottomAnchor, constant: 4),
            subLabel.leadingAnchor.constraint(equalTo: contentView.leadingAnchor, constant: 20),
            
            scrollTable.topAnchor.constraint(equalTo: subLabel.bottomAnchor, constant: 12),
            scrollTable.leadingAnchor.constraint(equalTo: contentView.leadingAnchor, constant: 20),
            scrollTable.trailingAnchor.constraint(equalTo: contentView.trailingAnchor, constant: -20),
            scrollTable.bottomAnchor.constraint(equalTo: resetButton.topAnchor, constant: -12),
            
            resetButton.leadingAnchor.constraint(equalTo: contentView.leadingAnchor, constant: 20),
            resetButton.bottomAnchor.constraint(equalTo: contentView.bottomAnchor, constant: -14)
        ])
        
        ConfigManager.shared.onShortcutsChanged = { [weak self] in
            DispatchQueue.main.async {
                self?.tableView.reloadData()
            }
        }
    }
    
    public func showPreferences() {
        showWindow(nil)
        window?.makeKeyAndOrderFront(nil)
        NSApp.activate(ignoringOtherApps: true)
        tableView.reloadData()
    }
    
    // MARK: - Table DataSource & Delegate
    public func numberOfRows(in tableView: NSTableView) -> Int {
        return ConfigManager.shared.slotKeys.count
    }
    
    public func tableView(_ tableView: NSTableView, viewFor tableColumn: NSTableColumn?, row: Int) -> NSView? {
        let keys = ConfigManager.shared.slotKeys
        guard row < keys.count else { return nil }
        let slotKey = keys[row]
        let shortcut = ConfigManager.shared.shortcuts.first(where: { $0.key == slotKey })
        let identifier = tableColumn?.identifier.rawValue ?? ""
        
        if identifier == "Key" {
            let cell = NSTableCellView()
            let label = NSTextField(labelWithString: slotKey)
            label.font = NSFont.monospacedDigitSystemFont(ofSize: 13, weight: .bold)
            label.alignment = .center
            label.wantsLayer = true
            label.layer?.cornerRadius = 5
            label.layer?.backgroundColor = NSColor.secondaryLabelColor.withAlphaComponent(0.18).cgColor
            label.translatesAutoresizingMaskIntoConstraints = false
            cell.addSubview(label)
            
            NSLayoutConstraint.activate([
                label.centerXAnchor.constraint(equalTo: cell.centerXAnchor),
                label.centerYAnchor.constraint(equalTo: cell.centerYAnchor),
                label.widthAnchor.constraint(equalToConstant: 22),
                label.heightAnchor.constraint(equalToConstant: 22)
            ])
            return cell
        } else if identifier == "App" {
            let cell = NSTableCellView()
            let icon = NSImageView()
            icon.translatesAutoresizingMaskIntoConstraints = false
            
            let name = NSTextField(labelWithString: "")
            name.font = NSFont.systemFont(ofSize: 13, weight: .medium)
            name.translatesAutoresizingMaskIntoConstraints = false
            
            if let s = shortcut, !s.path.isEmpty {
                icon.image = s.icon
                name.stringValue = s.name
                name.textColor = .labelColor
            } else {
                icon.image = NSImage(systemSymbolName: "plus.app", accessibilityDescription: nil)
                name.stringValue = "Empty (Drop App Here)"
                name.textColor = .tertiaryLabelColor
            }
            
            cell.addSubview(icon)
            cell.addSubview(name)
            
            NSLayoutConstraint.activate([
                icon.leadingAnchor.constraint(equalTo: cell.leadingAnchor, constant: 4),
                icon.centerYAnchor.constraint(equalTo: cell.centerYAnchor),
                icon.widthAnchor.constraint(equalToConstant: 20),
                icon.heightAnchor.constraint(equalToConstant: 20),
                
                name.leadingAnchor.constraint(equalTo: icon.trailingAnchor, constant: 8),
                name.trailingAnchor.constraint(equalTo: cell.trailingAnchor, constant: -4),
                name.centerYAnchor.constraint(equalTo: cell.centerYAnchor)
            ])
            return cell
        } else if identifier == "Action" {
            let cell = NSTableCellView()
            
            let chooseBtn = NSButton(title: "Choose...", target: self, action: #selector(chooseAppForRow(_:)))
            chooseBtn.bezelStyle = .rounded
            chooseBtn.controlSize = .small
            chooseBtn.tag = row
            chooseBtn.translatesAutoresizingMaskIntoConstraints = false
            
            let clearBtn = NSButton(title: "Clear", target: self, action: #selector(clearAppForRow(_:)))
            clearBtn.bezelStyle = .rounded
            clearBtn.controlSize = .small
            clearBtn.tag = row
            clearBtn.translatesAutoresizingMaskIntoConstraints = false
            
            let stack = NSStackView(views: [chooseBtn, clearBtn])
            stack.orientation = .horizontal
            stack.spacing = 6
            stack.translatesAutoresizingMaskIntoConstraints = false
            cell.addSubview(stack)
            
            NSLayoutConstraint.activate([
                stack.trailingAnchor.constraint(equalTo: cell.trailingAnchor, constant: -4),
                stack.centerYAnchor.constraint(equalTo: cell.centerYAnchor)
            ])
            return cell
        }
        
        return nil
    }
    
    @objc private func chooseAppForRow(_ sender: NSButton) {
        let row = sender.tag
        let keys = ConfigManager.shared.slotKeys
        guard row < keys.count else { return }
        let slotKey = keys[row]
        
        let openPanel = NSOpenPanel()
        openPanel.title = "Select Application for Slot [ \(slotKey) ]"
        openPanel.allowedContentTypes = [UTType.application]
        openPanel.allowsMultipleSelection = false
        openPanel.directoryURL = URL(fileURLWithPath: "/Applications")
        
        if openPanel.runModal() == .OK, let url = openPanel.url {
            ConfigManager.shared.setApp(forSlot: slotKey, fileURL: url)
        }
    }
    
    @objc private func clearAppForRow(_ sender: NSButton) {
        let row = sender.tag
        let keys = ConfigManager.shared.slotKeys
        guard row < keys.count else { return }
        let slotKey = keys[row]
        ConfigManager.shared.clearSlot(key: slotKey)
    }
    
    @objc private func resetDefaultsClicked() {
        ConfigManager.shared.resetToDefaults()
    }
}
