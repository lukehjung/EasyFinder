import AppKit

class AppDelegate: NSObject, NSApplicationDelegate {
    func applicationDidFinishLaunching(_ notification: Notification) {
        // Run as menu bar accessory (no dock icon clutter)
        NSApp.setActivationPolicy(.accessory)
        
        // Eagerly initialize configuration & defaults
        _ = ConfigManager.shared
        
        // Initialize menu bar companion
        StatusBarItemController.shared.setupStatusBar()
        
        // Wire up global hotkey listener for Option + Space
        HotKeyManager.shared.onTrigger = {
            HUDController.shared.toggle()
        }
        
        let registered = HotKeyManager.shared.registerGlobalHotKey()
        if registered {
            print("[EasyFinder] Ready. Press Option + Space to summon.")
        } else {
            print("[EasyFinder] Warning: Global hotkey could not be registered.")
        }
    }
    
    func applicationWillTerminate(_ notification: Notification) {
        HotKeyManager.shared.unregister()
    }
}

// Entry Point
let app = NSApplication.shared
let delegate = AppDelegate()
app.delegate = delegate
app.run()
