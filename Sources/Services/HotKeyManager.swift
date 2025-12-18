import Cocoa
import Carbon

class HotKeyManager {
    static let shared = HotKeyManager()
    
    var onHotKeyPressed: (() -> Void)?
    private var hotKeyRef: EventHotKeyRef?
    private var eventHandlerRef: EventHandlerRef?
    
    private init() {
        installEventHandler()
    }
    
    private func installEventHandler() {
        var eventType = EventTypeSpec(eventClass: OSType(kEventClassKeyboard), eventKind: OSType(kEventHotKeyPressed))
        
        let handler: EventHandlerUPP = { _, _, _ -> OSStatus in
            HotKeyManager.shared.onHotKeyPressed?()
            return noErr
        }
        
        InstallEventHandler(GetApplicationEventTarget(), handler, 1, &eventType, nil, &eventHandlerRef)
    }
    
    func register(keyCode: UInt32, modifiers: UInt32) {
        unregister()
        
        var hotKeyID = EventHotKeyID()
        hotKeyID.signature = OSType(1752460081) // random signature
        hotKeyID.id = 1
        
        let status = RegisterEventHotKey(keyCode, modifiers, hotKeyID, GetApplicationEventTarget(), 0, &hotKeyRef)
        if status != noErr {
            print("Error registering hotkey: \(status)")
        }
    }
    
    func unregister() {
        if let ref = hotKeyRef {
            UnregisterEventHotKey(ref)
            hotKeyRef = nil
        }
    }
    
    // Default: Option + Space
    // kVK_Space = 49
    // optionKey = 2048 (1 << 11)
    func registerDefault() {
        // Check UserDefaults
        let storedKey = UserDefaults.standard.integer(forKey: "Hotkey_Key")
        let storedMod = UserDefaults.standard.integer(forKey: "Hotkey_Mod")
        
        if storedKey == 0 && storedMod == 0 {
            register(keyCode: 49, modifiers: 2048) // Option + Space
        } else {
            register(keyCode: UInt32(storedKey), modifiers: UInt32(storedMod))
        }
    }
    
    func updateHotkey(keyCode: UInt32, modifiers: UInt32) {
        UserDefaults.standard.set(Int(keyCode), forKey: "Hotkey_Key")
        UserDefaults.standard.set(Int(modifiers), forKey: "Hotkey_Mod")
        register(keyCode: keyCode, modifiers: modifiers)
    }
}
