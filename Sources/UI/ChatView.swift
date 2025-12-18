import SwiftUI
import MarkdownUI

class LocalEventMonitor {
    private var monitor: Any?
    private let mask: NSEvent.EventTypeMask
    private let handler: (NSEvent) -> NSEvent?

    init(mask: NSEvent.EventTypeMask, handler: @escaping (NSEvent) -> NSEvent?) {
        self.mask = mask
        self.handler = handler
    }

    func start() {
        if monitor == nil {
            monitor = NSEvent.addLocalMonitorForEvents(matching: mask, handler: handler)
        }
    }

    func stop() {
        if let monitor = monitor {
            NSEvent.removeMonitor(monitor)
            self.monitor = nil
        }
    }
}

struct ChatView: View {
    @StateObject var aiService = AIService()
    @FocusState private var isFocused: Bool
    @State private var isAlwaysOnTop: Bool = true
    @State private var eventMonitor: LocalEventMonitor?
    
    var body: some View {
        VStack(spacing: 0) {
            // Header / Toolbar
            HStack {
                Text("AI Assistant")
                    .font(.headline)
                    .foregroundColor(.secondary)
                Spacer()
                
                Button(action: {
                    aiService.clearHistory()
                }) {
                    Image(systemName: "trash")
                        .foregroundColor(.secondary)
                }
                .buttonStyle(.plain)
                .padding(.trailing, 8)
                
                Toggle(isOn: $isAlwaysOnTop) {
                    Image(systemName: isAlwaysOnTop ? "pin.fill" : "pin.slash")
                }
                .toggleStyle(.button)
                .buttonStyle(.plain)
                .onChange(of: isAlwaysOnTop) { newValue in
                    NotificationCenter.default.post(name: NSNotification.Name("ToggleAlwaysOnTop"), object: nil, userInfo: ["isOn": newValue])
                }
            }
            .padding()
            .background(Color.black.opacity(0.1))
            
            // Chat History
            ScrollViewReader { proxy in
                ScrollView {
                    LazyVStack(alignment: .leading, spacing: 12) {
                        ForEach(aiService.messages) { msg in
                            MessageView(message: msg)
                        }
                        if aiService.isStreaming && !aiService.currentStreamingMessage.isEmpty {
                            MessageView(message: Message(role: "assistant", content: aiService.currentStreamingMessage), isStreaming: true)
                        }
                        // Dummy view for scrolling to bottom
                        Color.clear
                            .frame(height: 1)
                            .id("bottom")
                    }
                    .padding()
                }
                .onChange(of: aiService.currentStreamingMessage) { _ in
                    proxy.scrollTo("bottom", anchor: .bottom)
                }
                .onChange(of: aiService.messages.count) { _ in
                    proxy.scrollTo("bottom", anchor: .bottom)
                }
            }
            
            // Input Area
            HStack(alignment: .bottom, spacing: 8) {
                if #available(macOS 13.0, *) {
                    TextField("Ask anything...", text: $aiService.inputText, axis: .vertical)
                        .textFieldStyle(.plain)
                        .focused($isFocused)
                        .padding(10)
                        .background(Color.gray.opacity(0.2))
                        .cornerRadius(8)
                        .lineLimit(1...5)
                        .onSubmit {
                            // Keep default behavior or handle submit
                        }
                } else {
                    TextField("Ask anything...", text: $aiService.inputText)
                        .textFieldStyle(.plain)
                        .focused($isFocused)
                        .padding(10)
                        .background(Color.gray.opacity(0.2))
                        .cornerRadius(8)
                }
                
                Button(action: sendMessage) {
                    Image(systemName: "arrow.up")
                        .font(.system(size: 16, weight: .bold))
                        .foregroundColor(.white)
                        .frame(width: 20, height: 20) // Icon size
                        .padding(10) // Padding to match TextField's padding roughly
                }
                .background(aiService.inputText.trimmingCharacters(in: .whitespacesAndNewlines).isEmpty || aiService.isStreaming ? Color.gray : Color.blue)
                .cornerRadius(8)
                .buttonStyle(.plain)
                .disabled(aiService.inputText.trimmingCharacters(in: .whitespacesAndNewlines).isEmpty || aiService.isStreaming)
            }
            .padding()
        }
        .background(.ultraThinMaterial)
        .cornerRadius(16)
        .onAppear {
            isFocused = true
            
            eventMonitor = LocalEventMonitor(mask: .keyDown) { event in
                // Check if Enter key (36) is pressed
                if event.keyCode == 36 {
                    let modifiers = event.modifierFlags.intersection(.deviceIndependentFlagsMask)
                    
                    // Enter without modifiers -> Send
                    if modifiers.isEmpty {
                        // Check if we should send: window must be key, and we shouldn't be streaming
                        if let window = NSApp.keyWindow, 
                           let contentView = window.contentView,
                           contentView.subviews.contains(where: { $0.className.contains("Hosting") }) { // Rough check if it's our window
                             // Or simpler: check if the key window is the floating panel (we can check class or title, but title is hidden)
                             // Since our app only has this main floating panel and settings window.
                             // Settings window title is "Settings".
                             if window.title != "Settings" {
                                 Task { @MainActor in
                                     if !aiService.isStreaming {
                                         await aiService.sendMessage()
                                     }
                                 }
                                 return nil // Consume event
                             }
                        }
                    }
                    // Shift + Enter -> Allow default behavior (newline)
                }
                return event
            }
            eventMonitor?.start()
        }
        .onDisappear {
            eventMonitor?.stop()
        }
    }
    
    private func sendMessage() {
        Task {
            await aiService.sendMessage()
        }
    }
}

struct MessageView: View {
    let message: Message
    var isStreaming: Bool = false
    
    var body: some View {
        HStack(alignment: .top) {
            if message.role == "user" {
                Spacer()
                Text(message.content)
                    .padding(10)
                    .background(Color.blue.opacity(0.8))
                    .foregroundColor(.white)
                    .cornerRadius(12)
            } else {
                VStack(alignment: .leading) {
                    Markdown(message.content)
                        .padding(10)
                        .background(Color.gray.opacity(0.3))
                        .cornerRadius(12)
                        .textSelection(.enabled)
                }
                Spacer()
            }
        }
        .id(message.id)
    }
}
