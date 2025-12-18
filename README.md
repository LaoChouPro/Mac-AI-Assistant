<div align="center">

# Mac AI Assostamt
### On MacOS, use option+space to summon the AI assistant chat box, which runs in the menu bar.

</div>

---

## Features

- **Menu Bar App**: Runs quietly in the background with a status bar icon; no Dock icon to clutter your workspace.
- **Global Hotkey**: Instantly summon the chat window from anywhere using `Option + Space` (customizable).
- **Modern UI**: Features a sleek, rounded window with macOS visual effects (frosted glass/blur).
- **Streaming Responses**: Real-time streaming of AI responses for a fluid conversation experience.
- **Markdown Support**: Rich text rendering for code blocks, lists, and formatting.
- **Context-Aware**: Supports multi-turn conversations (clears on reset).
- **Productivity Focused**:
  - "Always on Top" mode to keep the chat visible while you work.
  - **Enter** to send, **Shift + Enter** for new lines.
  - Standard Edit menu support (Copy, Paste, Undo, Redo).
- **Customizable**:
  - Configurable API Key, Base URL, and Model Name.
  - Compatible with OpenAI-format APIs (e.g., SiliconFlow, DeepSeek).
  - "Launch at Login" support.

## Installation

1. Navigate to the `FastCallAI` directory.
2. Build the application:
   ```bash
   chmod +x bundle.sh
   ./bundle.sh
   ```
3. The compiled application will be available at `build/FastCallAI.app`.
4. Drag `FastCallAI.app` to your Applications folder or run it directly.

## Usage

1. **Launch**: Open the app. You will see a "sparkles" icon in your menu bar.
2. **Setup**: Click the menu bar icon and select **Settings**. Enter your API Key and configure the Model (defaults to `Qwen/Qwen2.5-7B-Instruct` via SiliconFlow).
3. **Chat**: Press `Option + Space` to open the chat window. Type your query and hit Enter.
4. **Manage**:
   - Use the "Pin" icon in the chat window to toggle "Always on Top".
   - Use the "Trash" icon to clear conversation history.
   - Use `Esc` to close the window.

## Requirements

- macOS 13.0 or later.

## Built With

- **Swift** & **SwiftUI**
- **AppKit** (for window management and menu bar integration)
- **Carbon** (for global hotkeys)
- **MarkdownUI** (for Markdown rendering)
- **SMAppService** (for launch at login)
