# EasyFinder 2.0 (Clone for Modern macOS)

A native, ultra-fast macOS hotkey launcher built from the ground up to replace **Easy Finder 2** on modern macOS (macOS 13 Ventura, 14 Sonoma, 15 Sequoia, and Apple Silicon).

---

## 🚀 How It Works

1. **Global Shortcut**: Press **`⌥ + Space` (Option + Space)** anywhere in macOS.
2. **Instant Floating HUD**: A sleek, frosted glass HUD appears centered on the active screen.
3. **Single-Key Launching**:
   * Press **`T`** → Opens **Terminal**
   * Press **`C`** → Opens **Google Chrome**
   * Press **`F`** → Opens **Finder**
   * Press **`N`** → Opens **Notes**
   * Press **`P`** → Opens **System Settings**
   * Press **`A`** → Opens **Calculator**
   * Press **`M`** → Opens **Mail**
   * Press **`E`** → Opens **TextEdit**
   * Press **`ESC`** → Dismiss HUD
   * Or start typing to filter applications in real-time and press **Return** to launch!

---

## ⚡ Why This Works on Modern macOS (When Easy Finder 2 Broke)

* **Apple Silicon Native (`arm64`)**: Compiled specifically for Apple Silicon (M1/M2/M3/M4) and modern Intel Macs.
* **No Accessibility Permissions Needed**: Uses Carbon's `RegisterEventHotKey` API for the global shortcut, completely avoiding fragile Accessibility permission prompts.
* **Modern AppKit & NSWorkspace**: Asynchronous dispatching (`openApplication`) compatible with macOS 13+.
* **Multi-Space & Full-Screen Support**: The floating HUD utilizes `.canJoinAllSpaces` and `.fullScreenAuxiliary` so it summons seamlessly over full-screen apps and across all Mission Control spaces.

---

## 🛠 Usage & Preferences

### Launch the App
```bash
open EasyFinder.app
```

### Menu Bar Companion
EasyFinder runs silently as a background menu bar item with an `EF` icon:
* **Toggle Launcher (⌥Space)**
* **Preferences...**: Add any app from `/Applications` and assign custom single-key shortcuts (`A–Z`, `0–9`).
* **Launch at Login**: Enable/disable automatic startup.
* **Quit EasyFinder**

### Customizing Shortcuts
Shortcuts are stored cleanly in JSON at:
```bash
~/Library/Application Support/EasyFinder/shortcuts.json
```
You can edit them directly in the Preferences window or modify the JSON file.

---

## 🔨 Building from Source

```bash
# Build debug binary
make build

# Build standalone EasyFinder.app bundle
make release

# Run directly
make run
```
