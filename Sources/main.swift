import Cocoa
import SwiftUI

// Entry Point
let app = NSApplication.shared
let delegate = AppDelegate()
app.delegate = delegate
app.setActivationPolicy(.accessory) 
app.run()

class AppDelegate: NSObject, NSApplicationDelegate {
    var statusItem: NSStatusItem?
    var panel: FloatingPanel!
    var settingsWindow: NSWindow!
    
    func applicationDidFinishLaunching(_ notification: Notification) {
        // Setup Menu Bar
        statusItem = NSStatusBar.system.statusItem(withLength: NSStatusItem.variableLength)
        if let button = statusItem?.button {
            button.image = NSImage(systemSymbolName: "sparkles", accessibilityDescription: "FastCallAI")
        }
        
        setupMenu()
        
        // Setup Floating Panel
        let screenRect = NSScreen.main?.visibleFrame ?? NSRect(x: 0, y: 0, width: 800, height: 600)
        let panelWidth: CGFloat = 600
        let panelHeight: CGFloat = 400
        let panelX = screenRect.midX - (panelWidth / 2)
        let panelY = screenRect.minY + 200 // Positioned lower-center
        
        let contentRect = NSRect(x: panelX, y: panelY, width: panelWidth, height: panelHeight)
        panel = FloatingPanel(contentRect: contentRect)
        
        let chatView = ChatView()
        let hostingView = NSHostingView(rootView: chatView)
        hostingView.autoresizingMask = [.width, .height]
        hostingView.frame = panel.contentView!.bounds
        panel.contentView?.addSubview(hostingView)
        
        // Setup Settings Window
        let settingsView = SettingsView()
        settingsWindow = NSWindow(
            contentRect: NSRect(x: 0, y: 0, width: 450, height: 350),
            styleMask: [.titled, .closable, .miniaturizable],
            backing: .buffered, defer: false)
        settingsWindow.center()
        settingsWindow.title = "Settings"
        settingsWindow.contentView = NSHostingView(rootView: settingsView)
        settingsWindow.isReleasedWhenClosed = false
        
        // Setup Hotkeys
        HotKeyManager.shared.registerDefault()
        HotKeyManager.shared.onHotKeyPressed = { [weak self] in
            DispatchQueue.main.async {
                self?.togglePanel()
            }
        }
        
        // Listen for Hotkey Reload
        NotificationCenter.default.addObserver(self, selector: #selector(reloadHotkey), name: NSNotification.Name("ReloadHotkey"), object: nil)
        
        // Listen for AlwaysOnTop toggle
        NotificationCenter.default.addObserver(self, selector: #selector(toggleAlwaysOnTop(_:)), name: NSNotification.Name("ToggleAlwaysOnTop"), object: nil)
    }
    
    func setupMenu() {
        // Status Bar Menu
        let menu = NSMenu()
        menu.addItem(NSMenuItem(title: "Settings...", action: #selector(showSettings), keyEquivalent: ","))
        menu.addItem(NSMenuItem.separator())
        menu.addItem(NSMenuItem(title: "Quit", action: #selector(terminateApp), keyEquivalent: "q"))
        statusItem?.menu = menu
        
        // Main Application Menu (for shortcuts like Cmd+C/V)
        let mainMenu = NSMenu()
        NSApp.mainMenu = mainMenu
        
        // App Menu
        let appMenuItem = NSMenuItem()
        mainMenu.addItem(appMenuItem)
        let appMenu = NSMenu()
        appMenuItem.submenu = appMenu
        appMenu.addItem(NSMenuItem(title: "About FastCallAI", action: #selector(NSApplication.orderFrontStandardAboutPanel(_:)), keyEquivalent: ""))
        appMenu.addItem(NSMenuItem(title: "Quit", action: #selector(terminateApp), keyEquivalent: "q"))
        
        // Edit Menu
        let editMenuItem = NSMenuItem()
        mainMenu.addItem(editMenuItem)
        let editMenu = NSMenu(title: "Edit")
        editMenuItem.submenu = editMenu
        
        editMenu.addItem(NSMenuItem(title: "Undo", action: Selector("undo:"), keyEquivalent: "z"))
        editMenu.addItem(NSMenuItem(title: "Redo", action: Selector("redo:"), keyEquivalent: "Z"))
        editMenu.addItem(NSMenuItem.separator())
        editMenu.addItem(NSMenuItem(title: "Cut", action: Selector("cut:"), keyEquivalent: "x"))
        editMenu.addItem(NSMenuItem(title: "Copy", action: Selector("copy:"), keyEquivalent: "c"))
        editMenu.addItem(NSMenuItem(title: "Paste", action: Selector("paste:"), keyEquivalent: "v"))
        editMenu.addItem(NSMenuItem(title: "Select All", action: Selector("selectAll:"), keyEquivalent: "a"))
    }
    
    @objc func togglePanel() {
        if panel.isVisible {
            panel.orderOut(nil)
        } else {
            panel.makeKeyAndOrderFront(nil)
            NSApp.activate(ignoringOtherApps: true)
        }
    }
    
    @objc func showSettings() {
        settingsWindow.makeKeyAndOrderFront(nil)
        NSApp.activate(ignoringOtherApps: true)
    }
    
    @objc func terminateApp() {
        NSApp.terminate(nil)
    }
    
    @objc func reloadHotkey() {
        let key = UserDefaults.standard.integer(forKey: "Hotkey_Key")
        let mod = UserDefaults.standard.integer(forKey: "Hotkey_Mod")
        if key != 0 {
            HotKeyManager.shared.updateHotkey(keyCode: UInt32(key), modifiers: UInt32(mod))
        }
    }
    
    @objc func toggleAlwaysOnTop(_ notification: Notification) {
        if let isOn = notification.userInfo?["isOn"] as? Bool {
            panel.level = isOn ? .floating : .normal
        }
    }
}
