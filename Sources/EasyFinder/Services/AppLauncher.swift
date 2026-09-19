import Foundation
import AppKit

public class AppLauncher {
    public static let shared = AppLauncher()
    
    private init() {}
    
    public func launch(shortcut: AppShortcut, completion: ((Bool) -> Void)? = nil) {
        var appURL: URL? = nil
        
        let pathURL = URL(fileURLWithPath: shortcut.path)
        if FileManager.default.fileExists(atPath: pathURL.path) {
            appURL = pathURL
        } else if let bundleId = shortcut.bundleIdentifier,
                  let resolvedURL = NSWorkspace.shared.urlForApplication(withBundleIdentifier: bundleId) {
            appURL = resolvedURL
        }
        
        guard let finalURL = appURL else {
            print("[EasyFinder] Cannot find application for shortcut: \(shortcut.name) at path \(shortcut.path)")
            completion?(false)
            return
        }
        
        let config = NSWorkspace.OpenConfiguration()
        config.activates = true
        config.addsToRecentItems = true
        
        NSWorkspace.shared.openApplication(at: finalURL, configuration: config) { app, error in
            DispatchQueue.main.async {
                if let error = error {
                    print("[EasyFinder] Failed to launch \(shortcut.name): \(error.localizedDescription)")
                    completion?(false)
                } else {
                    // Force bring app to front if needed
                    app?.activate(options: [.activateIgnoringOtherApps])
                    completion?(true)
                }
            }
        }
    }
}
