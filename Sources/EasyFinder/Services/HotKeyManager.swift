import Foundation
import Carbon
import AppKit

public class HotKeyManager {
    public static let shared = HotKeyManager()
    
    public var onTrigger: (() -> Void)?
    
    private var hotKeyRef: EventHotKeyRef?
    private var eventHandlerRef: EventHandlerRef?
    
    private init() {}
    
    /// Registers Option + Space globally without needing Accessibility permissions
    public func registerGlobalHotKey(keyCode: UInt32 = UInt32(kVK_Space), modifiers: UInt32 = UInt32(optionKey)) -> Bool {
        unregister()
        
        var eventType = EventTypeSpec(
            eventClass: OSType(kEventClassKeyboard),
            eventKind: UInt32(kEventHotKeyPressed)
        )
        
        let selfPointer = UnsafeMutableRawPointer(Unmanaged.passUnretained(self).toOpaque())
        
        let handlerStatus = InstallEventHandler(
            GetApplicationEventTarget(),
            { (_, eventRef, userData) -> OSStatus in
                guard let userData = userData, let event = eventRef else {
                    return OSStatus(eventNotHandledErr)
                }
                
                var hotKeyID = EventHotKeyID()
                let status = GetEventParameter(
                    event,
                    EventParamName(kEventParamDirectObject),
                    EventParamType(typeEventHotKeyID),
                    nil,
                    MemoryLayout<EventHotKeyID>.size,
                    nil,
                    &hotKeyID
                )
                
                if status == noErr && hotKeyID.id == 1 {
                    let manager = Unmanaged<HotKeyManager>.fromOpaque(userData).takeUnretainedValue()
                    DispatchQueue.main.async {
                        manager.onTrigger?()
                    }
                    return noErr
                }
                
                return OSStatus(eventNotHandledErr)
            },
            1,
            &eventType,
            selfPointer,
            &eventHandlerRef
        )
        
        guard handlerStatus == noErr else {
            print("[EasyFinder] Failed to install event handler: \(handlerStatus)")
            return false
        }
        
        let hotKeyID = EventHotKeyID(signature: OSType(0x45464E44), id: 1) // 'EFND', id 1
        let registerStatus = RegisterEventHotKey(
            keyCode,
            modifiers,
            hotKeyID,
            GetApplicationEventTarget(),
            0,
            &hotKeyRef
        )
        
        guard registerStatus == noErr else {
            print("[EasyFinder] Failed to register hot key: \(registerStatus)")
            return false
        }
        
        print("[EasyFinder] Global hotkey (Option + Space) successfully registered.")
        return true
    }
    
    public func unregister() {
        if let hotKeyRef = hotKeyRef {
            UnregisterEventHotKey(hotKeyRef)
            self.hotKeyRef = nil
        }
        if let eventHandlerRef = eventHandlerRef {
            RemoveEventHandler(eventHandlerRef)
            self.eventHandlerRef = nil
        }
    }
    
    deinit {
        unregister()
    }
}
