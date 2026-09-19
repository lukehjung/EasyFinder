import Foundation
import AppKit
import UniformTypeIdentifiers

public class ConfigManager {
    public static let shared = ConfigManager()
    
    public var onShortcutsChanged: (() -> Void)?
    public private(set) var shortcuts: [AppShortcut] = []
    
    public let slotKeys = ["1", "2", "3", "4", "5", "6", "7", "8", "9", "0"]
    
    private let fileManager = FileManager.default
    private let configDirectoryURL: URL
    private let configFileURL: URL
    
    public init() {
        let appSupport = fileManager.urls(for: .applicationSupportDirectory, in: .userDomainMask).first!
        self.configDirectoryURL = appSupport.appendingPathComponent("EasyFinder", isDirectory: true)
        self.configFileURL = configDirectoryURL.appendingPathComponent("shortcuts.json")
        
        load()
    }
    
    public func load() {
        do {
            if !fileManager.fileExists(atPath: configDirectoryURL.path) {
                try fileManager.createDirectory(at: configDirectoryURL, withIntermediateDirectories: true)
            }
            
            if fileManager.fileExists(atPath: configFileURL.path) {
                let data = try Data(contentsOf: configFileURL)
                let decoder = JSONDecoder()
                let loaded = try decoder.decode([AppShortcut].self, from: data)
                
                let hasNumericKeys = loaded.contains { Int($0.key) != nil }
                if hasNumericKeys {
                    self.shortcuts = normalizeSlots(loaded)
                    onShortcutsChanged?()
                    return
                }
            }
        } catch {
            print("[EasyFinder] Failed to load config: \(error.localizedDescription)")
        }
        
        self.shortcuts = defaultShortcuts()
        save()
    }
    
    public func save() {
        do {
            if !fileManager.fileExists(atPath: configDirectoryURL.path) {
                try fileManager.createDirectory(at: configDirectoryURL, withIntermediateDirectories: true)
            }
            let encoder = JSONEncoder()
            encoder.outputFormatting = .prettyPrinted
            let data = try encoder.encode(shortcuts)
            try data.write(to: configFileURL, options: .atomic)
            onShortcutsChanged?()
        } catch {
            print("[EasyFinder] Failed to save config: \(error.localizedDescription)")
        }
    }
    
    public func shortcut(forKey key: String) -> AppShortcut? {
        let normalized = key.lowercased()
        guard let shortcut = shortcuts.first(where: { $0.key == normalized }) else { return nil }
        return shortcut.path.isEmpty ? nil : shortcut
    }
    
    public func setApp(forSlot key: String, fileURL: URL) {
        let path = fileURL.path
        let bundle = Bundle(url: fileURL)
        let bundleId = bundle?.bundleIdentifier
        let appName = (try? fileURL.resourceValues(forKeys: [.localizedNameKey]).localizedName) ?? fileURL.deletingPathExtension().lastPathComponent
        
        setShortcut(key: key, name: appName, bundleIdentifier: bundleId, path: path)
    }
    
    public func setShortcut(key: String, name: String, bundleIdentifier: String?, path: String) {
        let normalized = key.lowercased()
        shortcuts.removeAll { $0.key == normalized }
        let newShortcut = AppShortcut(
            key: normalized,
            name: name,
            bundleIdentifier: bundleIdentifier,
            path: path
        )
        shortcuts.append(newShortcut)
        shortcuts = normalizeSlots(shortcuts)
        save()
    }
    
    public func moveOrSwapSlot(from sourceKey: String, to targetKey: String) {
        guard sourceKey != targetKey else { return }
        guard let sourceIndex = shortcuts.firstIndex(where: { $0.key == sourceKey }),
              let targetIndex = shortcuts.firstIndex(where: { $0.key == targetKey }) else { return }
        
        let sourceApp = shortcuts[sourceIndex]
        let targetApp = shortcuts[targetIndex]
        
        // Swap payloads between the two slots so numbers remain 1..9, 0 in sequence
        shortcuts[sourceIndex] = AppShortcut(
            id: sourceApp.id,
            key: sourceKey,
            name: targetApp.name,
            bundleIdentifier: targetApp.bundleIdentifier,
            path: targetApp.path
        )
        
        shortcuts[targetIndex] = AppShortcut(
            id: targetApp.id,
            key: targetKey,
            name: sourceApp.name,
            bundleIdentifier: sourceApp.bundleIdentifier,
            path: sourceApp.path
        )
        
        save()
    }
    
    public func clearSlot(key: String) {
        let normalized = key.lowercased()
        shortcuts.removeAll { $0.key == normalized }
        shortcuts.append(AppShortcut(key: normalized, name: "Empty (Drag App Here)", bundleIdentifier: nil, path: ""))
        shortcuts = normalizeSlots(shortcuts)
        save()
    }
    
    public func resetToDefaults() {
        shortcuts = defaultShortcuts()
        save()
    }
    
    private func normalizeSlots(_ list: [AppShortcut]) -> [AppShortcut] {
        var result: [AppShortcut] = []
        for key in slotKeys {
            if let existing = list.first(where: { $0.key == key }) {
                result.append(existing)
            } else {
                result.append(AppShortcut(key: key, name: "Empty (Drag App Here)", bundleIdentifier: nil, path: ""))
            }
        }
        return result
    }
    
    private func defaultShortcuts() -> [AppShortcut] {
        var list: [AppShortcut] = []
        
        func resolveApp(bundleId: String, fallbackPath: String, defaultName: String) -> (String, String)? {
            if let url = NSWorkspace.shared.urlForApplication(withBundleIdentifier: bundleId) {
                let name = (try? url.resourceValues(forKeys: [.localizedNameKey]).localizedName) ?? defaultName
                return (name, url.path)
            } else if fileManager.fileExists(atPath: fallbackPath) {
                let url = URL(fileURLWithPath: fallbackPath)
                let name = (try? url.resourceValues(forKeys: [.localizedNameKey]).localizedName) ?? defaultName
                return (name, fallbackPath)
            }
            return nil
        }
        
        let appDefinitions: [(String, String, String)] = [
            ("com.apple.Terminal", "/System/Applications/Utilities/Terminal.app", "Terminal"),
            ("com.google.Chrome", "/Applications/Google Chrome.app", "Google Chrome"),
            ("com.apple.finder", "/System/Library/CoreServices/Finder.app", "Finder"),
            ("com.microsoft.VSCode", "/Applications/Visual Studio Code.app", "VS Code"),
            ("com.apple.systempreferences", "/System/Applications/System Settings.app", "System Settings"),
            ("com.apple.Notes", "/System/Applications/Notes.app", "Notes"),
            ("com.apple.calculator", "/System/Applications/Calculator.app", "Calculator"),
            ("com.apple.mail", "/System/Applications/Mail.app", "Mail"),
            ("com.apple.Music", "/System/Applications/Music.app", "Music")
        ]
        
        for (i, key) in slotKeys.enumerated() {
            if i < appDefinitions.count {
                let (bundleId, fallback, name) = appDefinitions[i]
                if let (appName, path) = resolveApp(bundleId: bundleId, fallbackPath: fallback, defaultName: name) {
                    list.append(AppShortcut(key: key, name: appName, bundleIdentifier: bundleId, path: path))
                } else if bundleId == "com.google.Chrome", let safari = resolveApp(bundleId: "com.apple.Safari", fallbackPath: "/Applications/Safari.app", defaultName: "Safari") {
                    list.append(AppShortcut(key: key, name: safari.0, bundleIdentifier: "com.apple.Safari", path: safari.1))
                } else if bundleId == "com.microsoft.VSCode", let textEdit = resolveApp(bundleId: "com.apple.TextEdit", fallbackPath: "/System/Applications/TextEdit.app", defaultName: "TextEdit") {
                    list.append(AppShortcut(key: key, name: textEdit.0, bundleIdentifier: "com.apple.TextEdit", path: textEdit.1))
                } else {
                    list.append(AppShortcut(key: key, name: "Empty (Drag App Here)", bundleIdentifier: nil, path: ""))
                }
            } else {
                list.append(AppShortcut(key: key, name: "Empty (Drag App Here)", bundleIdentifier: nil, path: ""))
            }
        }
        
        return list
    }
}
