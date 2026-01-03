# ⌨️ KeyboardTranslit

**KeyboardTranslit** is a lightweight macOS utility that instantly fixes text typed in the wrong keyboard layout. No more deleting and retyping sentences when you forget to switch languages.

## ✨ Features

- 🔄 **Bidirectional Conversion**: Automatically detects and converts between Latin and Ukrainian Cyrillic layouts.
- ⌨️ **Global Hotkey**: Press `Control + Option + T` (default) to instantly transliterate selected text in any application.
- 📋 **Clipboard Preservation**: Your previously copied text is automatically restored to the clipboard a second after the operation.
- 🎯 **Background Operation**: Runs silently without a Dock icon. Accessible via the Menu Bar (top panel).
- 🌐 **System-Wide**: Works everywhere—browsers, messengers (Telegram, Slack), IDEs (Xcode, VS Code), and text editors.

---

## 🚀 Installation & Setup

Since this app is created by an independent developer, you need to follow these steps for the first launch:

1. **Download**: Download the latest `.zip` release, extract it, and move `KeyboardTranslit.app` to your **Applications** folder.
2. **First Launch**: Right-click the app and select **Open**. If macOS says the developer is "unidentified," go to `System Settings > Privacy & Security` and click **Open Anyway**.
3. **Accessibility Permission**: The app needs "Accessibility" access to simulate `Cmd+C` / `Cmd+V` keystrokes.
   - Go to `System Settings > Privacy & Security > Accessibility`.
   - Click the `+` button and add `KeyboardTranslit`.
4. **Login Items**: To keep the app running after a restart, add it to `System Settings > General > Login Items`.

> [!IMPORTANT]
> **If the app fails to launch (showing a "damaged" error):**
> Open Terminal and run the following command:
> `xattr -cr /Applications/KeyboardTranslit.app`

---

## 🎮 How to Use

1. Select the text you accidentally typed in the wrong layout (e.g., `ghbdtn`).
2. Press **⌃ ⌥ T** (Control + Option + T).
3. The text will be automatically replaced with the correct version (`привіт`).

---

## 🔧 Troubleshooting

- **Hotkey doesn't work**: Ensure you have granted access in the **Accessibility** settings. This is the most common issue.
- **Text is not replaced**: Try selecting the text again. Some apps (e.g., Terminals) might require additional permissions or have paste delays.
- **How to Quit**: Find the keyboard icon in the top Menu Bar (near the clock), click it, and select **Quit**.

---

## 🛠 Technical Details

- **Language**: Swift 5 (Carbon & Cocoa)
- **Architecture**: Universal (Apple Silicon + Intel)
- **Privacy**: The app does not collect data, has no internet access, and works entirely offline.

---

## 📜 License

This project is licensed under the MIT License - see the [LICENSE](LICENSE) file for details.

**Made with ❤️**
