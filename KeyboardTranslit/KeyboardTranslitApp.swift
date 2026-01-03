//
//  KeyboardTranslitApp.swift
//  KeyboardTranslit
//
//  Created by Stanislav Hlukhanych on 02.01.2026.
//

import Cocoa
import Carbon

// MARK: - Transliteration Maps
private struct TransliterationMaps {
    static let latinToCyrillic: [Character: Character] = [
        "q": "й", "w": "ц", "e": "у", "r": "к", "t": "е", "y": "н", "u": "г", "i": "ш", "o": "щ", "p": "з",
        "[": "х", "]": "ї", "a": "ф", "s": "і", "d": "в", "f": "а", "g": "п", "h": "р", "j": "о", "k": "л",
        "l": "д", ";": "ж", "'": "є", "z": "я", "x": "ч", "c": "с", "v": "м", "b": "и", "n": "т", "m": "ь",
        ",": "б", ".": "ю", "/": ".", "\\": "ʼ",
        "Q": "Й", "W": "Ц", "E": "У", "R": "К", "T": "Е", "Y": "Н", "U": "Г", "I": "Ш", "O": "Щ", "P": "З",
        "{": "Х", "}": "Ї", "A": "Ф", "S": "І", "D": "В", "F": "А", "G": "П", "H": "Р", "J": "О", "K": "Л",
        "L": "Д", ":": "Ж", "\"": "Є", "Z": "Я", "X": "Ч", "C": "С", "V": "М", "B": "И", "N": "Т", "M": "Ь",
        "<": "Б", ">": "Ю", "?": ","
    ]
    
    static let cyrillicToLatin: [Character: Character] = {
        Dictionary(uniqueKeysWithValues: latinToCyrillic.map { ($1, $0) })
    }()
}

@main
@MainActor
class AppDelegate: NSObject, NSApplicationDelegate {
    private var eventTap: CFMachPort?
    private var statusItem: NSStatusItem?
    
    func applicationDidFinishLaunching(_ notification: Notification) {
        // Hide from Dock first
        NSApp.setActivationPolicy(.accessory)
        
        // Check for accessibility permissions
        let trusted = AXIsProcessTrusted()
        if !trusted {
            let alert = NSAlert()
            alert.messageText = "Accessibility Permission Required"
            alert.informativeText = "This app needs accessibility permissions to function. Please enable it in System Preferences > Security & Privacy > Privacy > Accessibility."
            alert.alertStyle = .warning
            alert.addButton(withTitle: "Open System Preferences")
            alert.addButton(withTitle: "Quit")
            
            if alert.runModal() == .alertFirstButtonReturn {
                NSWorkspace.shared.open(URL(string: "x-apple.systempreferences:com.apple.preference.security?Privacy_Accessibility")!)
            }
            NSApp.terminate(nil)
            return
        }
        
        // Set up Menu Bar UI
        setupMenuBar()
        
        // Register global hotkey (Control + Shift + T)
        registerGlobalHotkey()
    }
    
    private func setupMenuBar() {
        statusItem = NSStatusBar.system.statusItem(withLength: NSStatusItem.variableLength)
        
        if let button = statusItem?.button {
            // Try to use system keyboard symbol, fallback to text
            if let image = NSImage(systemSymbolName: "keyboard", accessibilityDescription: "Keyboard Layout") {
                button.image = image
            } else {
                button.title = "Layout"
            }
        }
        
        // Create menu
        let menu = NSMenu()
        menu.addItem(NSMenuItem(title: "Quit", action: #selector(quitApp), keyEquivalent: "q"))
        
        statusItem?.menu = menu
    }
    
    @objc private func quitApp() {
        NSApp.terminate(nil)
    }
    
    private func registerGlobalHotkey() {
        let eventSpec = EventTypeSpec(eventClass: OSType(kEventClassKeyboard), eventKind: UInt32(kEventHotKeyPressed))
        var eventHandler: EventHandlerRef?
        
        InstallEventHandler(GetApplicationEventTarget(), { (_, inEvent, userData) -> OSStatus in
            guard let userData = userData else { return OSStatus(eventNotHandledErr) }
            let appDelegate = Unmanaged<AppDelegate>.fromOpaque(userData).takeUnretainedValue()
            appDelegate.handleHotkey()
            return noErr
        }, 1, [eventSpec], Unmanaged.passUnretained(self).toOpaque(), &eventHandler)
        
        // Register Control + Option + T (keycode 17 for 'T')
        var hotKeyRef: EventHotKeyRef?
        let hotKeyID = EventHotKeyID(signature: OSType(0x54524C54), id: 1) // 'TRLT'
        RegisterEventHotKey(17, UInt32(shiftKey | controlKey), hotKeyID, GetApplicationEventTarget(), 0, &hotKeyRef)
    }
    
    private func handleHotkey() {
        // Small delay to ensure the hotkey doesn't interfere
        DispatchQueue.main.asyncAfter(deadline: .now() + 0.1) { [weak self] in
            self?.performTransliteration()
        }
    }
    
    private func performTransliteration() {
        // Step 1: Save current clipboard content
        let pasteboard = NSPasteboard.general
        let originalContent = pasteboard.string(forType: .string)
        let initialChangeCount = pasteboard.changeCount
        
        // Step 2: Simulate Command+C to copy selected text
        simulateKeyPress(keyCode: 8, flags: .maskCommand) // C key
        
        // Step 3: Wait for clipboard to update using changeCount
        var copiedText: String?
        let maxAttempts = 20 // 200ms total wait time
        for _ in 0..<maxAttempts {
            usleep(10_000) // 10ms delay
            if pasteboard.changeCount != initialChangeCount {
                copiedText = pasteboard.string(forType: .string)
                break
            }
        }
        
        // Step 4: Validate copied text
        guard let text = copiedText, !text.isEmpty else {
            // Restore original clipboard if nothing was copied
            if let original = originalContent {
                pasteboard.clearContents()
                pasteboard.setString(original, forType: .string)
            }
            return
        }
        
        // Step 5: Transliterate
        let transliteratedText = transliterate(text)
        
        // Step 6: Put transliterated text to clipboard
        pasteboard.clearContents()
        pasteboard.setString(transliteratedText, forType: .string)
        
        // Step 7: Simulate Command+V to paste
        simulateKeyPress(keyCode: 9, flags: .maskCommand) // V key
        
        // Step 8: Restore original clipboard content after a delay (0.6s to ensure paste completes)
        DispatchQueue.main.asyncAfter(deadline: .now() + 0.6) {
            if let original = originalContent {
                pasteboard.clearContents()
                pasteboard.setString(original, forType: .string)
            }
        }
    }
    
    private func transliterate(_ text: String) -> String {
        var result = ""
        
        // Determine direction: check if text contains more Cyrillic or Latin
        let cyrillicCount = text.filter { TransliterationMaps.cyrillicToLatin[$0] != nil }.count
        let latinCount = text.filter { TransliterationMaps.latinToCyrillic[$0] != nil }.count
        
        let useCyrillicToLatin = cyrillicCount > latinCount
        let map = useCyrillicToLatin ? TransliterationMaps.cyrillicToLatin : TransliterationMaps.latinToCyrillic
        
        for char in text {
            if let mapped = map[char] {
                result.append(mapped)
            } else {
                result.append(char)
            }
        }
        
        return result
    }
    
    private func simulateKeyPress(keyCode: CGKeyCode, flags: CGEventFlags) {
        let keyDown = CGEvent(keyboardEventSource: nil, virtualKey: keyCode, keyDown: true)
        let keyUp = CGEvent(keyboardEventSource: nil, virtualKey: keyCode, keyDown: false)
        
        keyDown?.flags = flags
        keyUp?.flags = flags
        
        keyDown?.post(tap: .cghidEventTap)
        keyUp?.post(tap: .cghidEventTap)
    }
    
    static func main() {
        let app = NSApplication.shared
        let delegate = AppDelegate()
        app.delegate = delegate
        app.run()
    }
}
