import Foundation
import AppKit
import UniformTypeIdentifiers

public struct AppShortcut: Identifiable, Codable, Equatable {
    public var id: UUID
    public var key: String           // e.g. "t", "c", "v", "1"
    public var name: String          // e.g. "Terminal"
    public var bundleIdentifier: String?
    public var path: String          // e.g. "/System/Applications/Utilities/Terminal.app"
    
    public init(id: UUID = UUID(), key: String, name: String, bundleIdentifier: String? = nil, path: String) {
        self.id = id
        self.key = key.lowercased()
        self.name = name
        self.bundleIdentifier = bundleIdentifier
        self.path = path
    }
    
    public var icon: NSImage {
        if FileManager.default.fileExists(atPath: path) {
            return NSWorkspace.shared.icon(forFile: path)
        }
        if let bundleId = bundleIdentifier,
           let url = NSWorkspace.shared.urlForApplication(withBundleIdentifier: bundleId) {
            return NSWorkspace.shared.icon(forFile: url.path)
        }
        return NSWorkspace.shared.icon(for: .application)
    }
    
    public var exists: Bool {
        if FileManager.default.fileExists(atPath: path) {
            return true
        }
        if let bundleId = bundleIdentifier,
           NSWorkspace.shared.urlForApplication(withBundleIdentifier: bundleId) != nil {
            return true
        }
        return false
    }
}
