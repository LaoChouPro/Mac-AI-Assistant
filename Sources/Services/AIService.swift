import Foundation

class AIService: ObservableObject {
    @Published var messages: [Message] = []
    @Published var isStreaming: Bool = false
    @Published var currentStreamingMessage: String = ""
    @Published var inputText: String = "" // Added to support access from EventMonitor
    
    private var apiKey: String {
        UserDefaults.standard.string(forKey: "OpenAI_API_Key") ?? ""
    }
    
    // Default to a standard OpenAI-compatible endpoint. Users can change this in settings if needed.
    private var apiBaseURL: String {
        UserDefaults.standard.string(forKey: "API_Base_URL") ?? "https://api.siliconflow.cn/v1/chat/completions"
    }

    private var modelName: String {
        UserDefaults.standard.string(forKey: "AI_Model_Name") ?? "Qwen/Qwen2.5-7B-Instruct"
    }
    
    func sendMessage(_ text: String? = nil) async {
        let textToSend = text ?? self.inputText
        guard !textToSend.trimmingCharacters(in: .whitespacesAndNewlines).isEmpty else { return }
        
        await MainActor.run {
            self.inputText = ""
        }
        
        let userMsg = Message(role: "user", content: textToSend)
        
        await MainActor.run {
            self.messages.append(userMsg)
            self.isStreaming = true
            self.currentStreamingMessage = ""
        }
        
        do {
            try await streamResponse(for: messages)
        } catch {
            await MainActor.run {
                self.messages.append(Message(role: "assistant", content: "Error: \(error.localizedDescription)"))
                self.isStreaming = false
            }
        }
    }
    
    private func streamResponse(for history: [Message]) async throws {
        guard let url = URL(string: apiBaseURL) else {
            throw URLError(.badURL)
        }
        
        var request = URLRequest(url: url)
        request.httpMethod = "POST"
        request.setValue("Bearer \(apiKey)", forHTTPHeaderField: "Authorization")
        request.setValue("application/json", forHTTPHeaderField: "Content-Type")
        
        let messagesPayload = history.map { ["role": $0.role, "content": $0.content] }
        
        let body: [String: Any] = [
            "model": modelName,
            "messages": messagesPayload,
            "stream": true
        ]
        
        request.httpBody = try JSONSerialization.data(withJSONObject: body)
        
        let (result, response) = try await URLSession.shared.bytes(for: request)
        
        guard let httpResponse = response as? HTTPURLResponse,
              (200...299).contains(httpResponse.statusCode) else {
            let statusCode = (response as? HTTPURLResponse)?.statusCode ?? -1
             throw NSError(domain: "AIService", code: statusCode, userInfo: [NSLocalizedDescriptionKey: "Server returned status code \(statusCode)"])
        }
        
        for try await line in result.lines {
            guard line.hasPrefix("data: "), line != "data: [DONE]" else { continue }
            
            let dataStr = String(line.dropFirst(6))
            guard let data = dataStr.data(using: .utf8),
                  let json = try? JSONSerialization.jsonObject(with: data) as? [String: Any],
                  let choices = json["choices"] as? [[String: Any]],
                  let firstChoice = choices.first,
                  let delta = firstChoice["delta"] as? [String: Any],
                  let content = delta["content"] as? String else {
                continue
            }
            
            await MainActor.run {
                self.currentStreamingMessage += content
            }
        }
        
        await MainActor.run {
            let finalMsg = Message(role: "assistant", content: self.currentStreamingMessage)
            self.messages.append(finalMsg)
            self.currentStreamingMessage = ""
            self.isStreaming = false
        }
    }
    
    func clearHistory() {
        messages.removeAll()
    }
}
