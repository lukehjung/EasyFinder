# EasyFinder 2.0 (Clone for Modern macOS)

A lightweight, ultra-fast macOS hotkey launcher built from the ground up to replace **Easy Finder 2** on modern macOS (macOS 13 Ventura, macOS 14 Sonoma, macOS 15+ Sequoia, and Apple Silicon).

---

## 🚀 How It Works

1. **Global Shortcut**: Press **`⌥ + Space` (Option + Space)** anywhere in macOS, or click the **`[ ⌥ ]`** icon in your menu bar.
2. **Top-Bar Anchored Palette**: A compact, frosted-glass dropdown appears directly beneath your menu bar.
3. **Numbered Muscle-Memory Launching**:
   * Press **`1`** → Opens **Terminal**
   * Press **`2`** → Opens **Google Chrome**
   * Press **`3`** → Opens **Finder**
   * Press **`4`** → Opens **TextEdit / VS Code**
   * Press **`5`** → Opens **System Settings**
   * Press **`6`** → Opens **Notes**
   * Press **`7`** → Opens **Calculator**
   * Press **`8`** → Opens **Mail**
   * Press **`9`** → Opens **Music**
   * Press **`0`** → Slot 10 (Customizable)
   * Press **`ESC`** → Dismiss palette (or click anywhere outside)

---

## 🔄 Drag-to-Reorder & Customization

* **Reorder Apps Directly on the Palette**:
  * Hover over any application row to reveal the drag grip (`☰`).
  * Click and drag the row to any other number slot — the apps will swap positions while keeping numbers `1` through `9`, `0` in order!
* **Assign Apps via Drag & Drop**:
  * Drag any `.app` file directly from Finder or `/Applications` onto any slot in the palette to assign it immediately.
* **Per-Slot File Picker**:
  * Hover over any row and click the **`…`** button (or click any empty slot) to browse and select an application.
* **Preferences Window**:
  * Click the **`⚙`** icon in the palette header or select **Preferences...** from the menu bar item to view all 10 slots with "Choose..." and "Clear" buttons.

---

## ⚡ Why This Works on Modern macOS (When Easy Finder 2 Broke)

* **Apple Silicon Native (`arm64`)**: Native 64-bit universal/arm64 binary (~300 KB footprint, ~20MB RAM).
* **Zero Accessibility Permissions Needed**: Uses Carbon's `RegisterEventHotKey` API for the global shortcut, completely eliminating fragile Accessibility permission prompts that broke legacy utilities on modern macOS.
* **Modern AppKit & NSWorkspace**: Modern asynchronous app dispatching (`openApplication`) compatible with macOS 13+.
* **Multi-Space & Full-Screen Support**: Utilizes `.canJoinAllSpaces` and `.fullScreenAuxiliary` so the palette summons smoothly over full-screen apps and across all Mission Control spaces.

---

## 🛠 Menu Bar Companion

EasyFinder runs silently as a background menu bar item with a sharp vector **`[ ⌥ ]`** keycap icon:
* **Left-Click**: Drops down the launcher palette right under the icon.
* **Right-Click**: Displays a context menu listing all configured programs with their hotkey numbers, plus **Preferences...**, **Launch at Login**, and **Quit**.

---

## 📂 Configuration Storage

All shortcuts and slot orders are stored cleanly in JSON at:
```bash
~/Library/Application Support/EasyFinder/shortcuts.json
```

---

## 🔨 Building from Source

```bash
# Clone the repository
git clone https://github.com/lukehjung/EasyFinder.git
cd EasyFinder

# Build debug binary
make build

# Build standalone EasyFinder.app bundle & release zip
make release

# Run directly
make run
```
