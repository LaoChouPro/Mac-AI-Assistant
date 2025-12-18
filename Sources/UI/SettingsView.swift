import SwiftUI
import ServiceManagement

struct SettingsView: View {
    @AppStorage("OpenAI_API_Key") private var apiKey: String = ""
    @AppStorage("API_Base_URL") private var apiBaseURL: String = "https://api.siliconflow.cn/v1/chat/completions"
    @AppStorage("AI_Model_Name") private var modelName: String = "Qwen/Qwen2.5-7B-Instruct"
    @AppStorage("Hotkey_Key") private var hotkeyKey: Int = 49 // Space
    @AppStorage("Hotkey_Mod") private var hotkeyMod: Int = 2048 // Option
    
    // 2048 = Option, 4096 = Ctrl, 256 = Cmd, 512 = Shift
    let modifiers: [(String, Int)] = [
        ("Option", 2048),
        ("Command", 256),
        ("Control", 4096),
        ("Shift", 512)
    ]
    
    var body: some View {
        Form {
            Section(header: Text("API Configuration")) {
                SecureField("API Key", text: $apiKey)
                    .textFieldStyle(.roundedBorder)
                TextField("Base URL", text: $apiBaseURL)
                    .textFieldStyle(.roundedBorder)
                TextField("Model Name", text: $modelName)
                    .textFieldStyle(.roundedBorder)
            }
            
            Section(header: Text("Shortcuts")) {
                HStack {
                    Text("Modifier:")
                    Picker("", selection: $hotkeyMod) {
                        ForEach(modifiers, id: \.1) { mod in
                            Text(mod.0).tag(mod.1)
                        }
                    }
                    .pickerStyle(.menu)
                    .onChange(of: hotkeyMod) { _ in reloadHotkey() }
                }
                
                HStack {
                    Text("Key Code (Decimal):")
                    TextField("Key Code", value: $hotkeyKey, formatter: NumberFormatter())
                        .textFieldStyle(.roundedBorder)
                        .frame(width: 60)
                        .onChange(of: hotkeyKey) { _ in reloadHotkey() }
                    
                    Text("(Space=49, Return=36)")
                        .font(.caption)
                        .foregroundColor(.secondary)
                }
                
                Button("Reset to Option + Space") {
                    hotkeyKey = 49
                    hotkeyMod = 2048
                    reloadHotkey()
                }
            }
            
            Section {
                Toggle("Launch at Login", isOn: Binding(
                    get: { SMAppService.mainApp.status == .enabled },
                    set: { newValue in
                        do {
                            if newValue {
                                try SMAppService.mainApp.register()
                            } else {
                                try SMAppService.mainApp.unregister()
                            }
                        } catch {
                            print("Failed to update launch at login: \(error)")
                        }
                    }
                ))
                .help("Launch at login requires the app to be in the Applications folder or properly signed.")
                
                Button("Quit App") {
                    NSApplication.shared.terminate(nil)
                }
                .foregroundColor(.red)
            }
        }
        .padding()
        .frame(width: 450, height: 350)
    }
    
    private func reloadHotkey() {
        NotificationCenter.default.post(name: NSNotification.Name("ReloadHotkey"), object: nil)
    }
}
