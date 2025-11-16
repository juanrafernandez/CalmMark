//
//  CalmMarkApp.swift
//  CalmMark
//
//  Created by Claude on 2025-11-15.
//  A minimalist, native Markdown editor for macOS
//

import SwiftUI
import AppKit

@main
struct CalmMarkApp: App {
    @NSApplicationDelegateAdaptor(AppDelegate.self) var appDelegate
    @State private var showDocumentMode = false

    var body: some Scene {
        // Main Project/Folder mode
        WindowGroup("CalmMark") {
            ProjectContentView()
                .environmentObject(appDelegate.tabManagerBridge)
        }
        .commands {
            CalmMarkCommands()
        }

        // Classic Document mode (for single files)
        DocumentGroup(newDocument: CalmMarkDocument()) { file in
            ContentView(document: file.$document)
        }
        .commands {
            CalmMarkCommands()
        }

        #if os(macOS)
        Settings {
            PreferencesView()
        }
        #endif
    }
}

// MARK: - App Delegate

class AppDelegate: NSObject, NSApplicationDelegate, ObservableObject {
    let tabManagerBridge = TabManagerBridge()
    private var windowDelegate: ProjectWindowDelegate?

    func applicationDidFinishLaunching(_ notification: Notification) {
        print("🚀 [AppDelegate] Application did finish launching")

        // Configurar window delegate después de un pequeño delay para que la ventana esté lista
        DispatchQueue.main.asyncAfter(deadline: .now() + 0.5) { [weak self] in
            guard let self = self else { return }
            self.setupWindowDelegate()
        }
    }

    private func setupWindowDelegate() {
        print("🔍 [AppDelegate] Setting up window delegate...")
        print("🔍 [AppDelegate] Number of windows: \(NSApp.windows.count)")

        // Encontrar la ventana principal (ProjectContentView)
        if let mainWindow = NSApp.windows.first(where: { $0.isMainWindow || $0.isKeyWindow }) {
            print("🪟 [AppDelegate] Found main window: \(mainWindow.title)")

            guard let tabManager = tabManagerBridge.tabManager else {
                print("⚠️ [AppDelegate] TabManager not connected yet, will retry...")
                // Reintentar después de otro delay
                DispatchQueue.main.asyncAfter(deadline: .now() + 0.5) { [weak self] in
                    self?.setupWindowDelegate()
                }
                return
            }

            // Crear y configurar el delegate
            windowDelegate = ProjectWindowDelegate(tabManager: tabManager)
            mainWindow.delegate = windowDelegate
            print("✅ [AppDelegate] Window delegate configured successfully!")
        } else if let anyWindow = NSApp.windows.first {
            print("🪟 [AppDelegate] Using first available window: \(anyWindow.title)")

            guard let tabManager = tabManagerBridge.tabManager else {
                print("⚠️ [AppDelegate] TabManager not connected yet, will retry...")
                DispatchQueue.main.asyncAfter(deadline: .now() + 0.5) { [weak self] in
                    self?.setupWindowDelegate()
                }
                return
            }

            windowDelegate = ProjectWindowDelegate(tabManager: tabManager)
            anyWindow.delegate = windowDelegate
            print("✅ [AppDelegate] Window delegate configured successfully!")
        } else {
            print("❌ [AppDelegate] No windows found")
        }
    }

    // Hacer que la app se cierre cuando se cierra la última ventana
    func applicationShouldTerminateAfterLastWindowClosed(_ sender: NSApplication) -> Bool {
        print("🪟 [AppDelegate] Last window closed, app will terminate")
        return true
    }

    func applicationShouldTerminate(_ sender: NSApplication) -> NSApplication.TerminateReply {
        print("🚪 [AppDelegate] applicationShouldTerminate called (from Cmd+Q or Quit menu)")

        // Verificar si hay archivos con cambios sin guardar
        guard let tabManager = tabManagerBridge.tabManager else {
            print("⚠️ [AppDelegate] TabManager is nil, terminating immediately")
            return .terminateNow
        }

        print("📋 [AppDelegate] TabManager connected, checking dirty files...")
        let dirtyFiles = tabManager.openFiles.filter { $0.isDirty }
        print("📋 [AppDelegate] Found \(dirtyFiles.count) dirty files out of \(tabManager.openFiles.count) total")

        if dirtyFiles.isEmpty {
            print("✅ [AppDelegate] No dirty files, terminating")
            return .terminateNow
        }

        // Mostrar diálogo al usuario
        print("🔔 [AppDelegate] Showing quit confirmation dialog...")
        let alert = NSAlert()
        alert.messageText = "Do you want to save changes before quitting?"
        alert.informativeText = "\(dirtyFiles.count) file(s) have unsaved changes."
        alert.addButton(withTitle: "Save All")
        alert.addButton(withTitle: "Don't Save")
        alert.addButton(withTitle: "Cancel")
        alert.alertStyle = .warning

        let response = alert.runModal()

        switch response {
        case .alertFirstButtonReturn: // Save All
            print("💾 [AppDelegate] User chose: Save All")
            tabManager.saveAllFiles()
            return .terminateNow
        case .alertSecondButtonReturn: // Don't Save
            print("❌ [AppDelegate] User chose: Don't Save (Hot Exit will preserve content)")
            // Hot Exit guardará automáticamente el contenido sin guardar
            return .terminateNow
        default: // Cancel
            print("🚫 [AppDelegate] User chose: Cancel")
            return .terminateCancel
        }
    }
}

// Bridge para conectar TabManager con AppDelegate
class TabManagerBridge: ObservableObject {
    weak var tabManager: TabManager?
}

// MARK: - Window Delegate

class ProjectWindowDelegate: NSObject, NSWindowDelegate {
    weak var tabManager: TabManager?

    init(tabManager: TabManager) {
        self.tabManager = tabManager
        super.init()
    }

    func windowShouldClose(_ sender: NSWindow) -> Bool {
        print("🚪 [WindowDelegate] windowShouldClose called (RED CLOSE BUTTON CLICKED)")

        guard let tabManager = tabManager else {
            print("⚠️ [WindowDelegate] TabManager is nil, allowing close")
            return true
        }

        let dirtyFiles = tabManager.openFiles.filter { $0.isDirty }
        print("📋 [WindowDelegate] Found \(dirtyFiles.count) dirty files out of \(tabManager.openFiles.count) total")

        if dirtyFiles.isEmpty {
            print("✅ [WindowDelegate] No dirty files, allowing close")
            return true
        }

        // Mostrar diálogo al usuario
        print("🔔 [WindowDelegate] Showing close confirmation dialog...")
        let alert = NSAlert()
        alert.messageText = "Do you want to save changes before closing?"
        alert.informativeText = "\(dirtyFiles.count) file(s) have unsaved changes."
        alert.addButton(withTitle: "Save All")
        alert.addButton(withTitle: "Don't Save")
        alert.addButton(withTitle: "Cancel")
        alert.alertStyle = .warning

        let response = alert.runModal()

        switch response {
        case .alertFirstButtonReturn: // Save All
            print("💾 [WindowDelegate] User chose: Save All")
            tabManager.saveAllFiles()
            return true
        case .alertSecondButtonReturn: // Don't Save
            print("❌ [WindowDelegate] User chose: Don't Save (Hot Exit will preserve content)")
            // Hot Exit guardará automáticamente el contenido sin guardar
            return true
        default: // Cancel
            print("🚫 [WindowDelegate] User chose: Cancel - window will NOT close")
            return false
        }
    }
}

struct CalmMarkCommands: Commands {
    var body: some Commands {
        CommandGroup(after: .newItem) {
            Divider()

            Button("Open Folder...") {
                NotificationCenter.default.post(name: .openFolder, object: nil)
            }
            .keyboardShortcut("O", modifiers: [.command, .shift])
        }

        // View commands for switching between modes
        CommandMenu("View") {
            Button("Toggle Sidebar") {
                NotificationCenter.default.post(name: .toggleSidebar, object: nil)
            }
            .keyboardShortcut("0", modifiers: [.command])

            Button("Toggle Preview Panel") {
                NotificationCenter.default.post(name: .togglePreviewPanel, object: nil)
            }
            .keyboardShortcut("9", modifiers: [.command, .option])

            Button("Toggle Log Panel") {
                NotificationCenter.default.post(name: .toggleLogPanel, object: nil)
            }
            .keyboardShortcut("L", modifiers: [.command, .shift])

            Divider()

            Button("Editor Only") {
                NotificationCenter.default.post(name: .changeViewMode, object: ViewMode.editor)
            }
            .keyboardShortcut("1", modifiers: [.command])

            Button("Preview Only") {
                NotificationCenter.default.post(name: .changeViewMode, object: ViewMode.preview)
            }
            .keyboardShortcut("2", modifiers: [.command])

            Button("Split View") {
                NotificationCenter.default.post(name: .changeViewMode, object: ViewMode.split)
            }
            .keyboardShortcut("3", modifiers: [.command])
        }

        // File commands
        CommandGroup(replacing: .saveItem) {
            Button("Save") {
                NotificationCenter.default.post(name: .saveActiveFile, object: nil)
            }
            .keyboardShortcut("S", modifiers: [.command])

            Button("Save All") {
                NotificationCenter.default.post(name: .saveAllFiles, object: nil)
            }
            .keyboardShortcut("S", modifiers: [.command, .option])

            Divider()

            Button("Close Tab") {
                NotificationCenter.default.post(name: .closeActiveTab, object: nil)
            }
            .keyboardShortcut("W", modifiers: [.command])

            Button("Close All Tabs") {
                NotificationCenter.default.post(name: .closeAllTabs, object: nil)
            }
            .keyboardShortcut("W", modifiers: [.command, .option])
        }

        // Export commands
        CommandMenu("Export") {
            Button("Export as HTML...") {
                NotificationCenter.default.post(name: .exportHTML, object: nil)
            }
            .keyboardShortcut("E", modifiers: [.command, .shift])

            Button("Export as PDF...") {
                NotificationCenter.default.post(name: .exportPDF, object: nil)
            }
            .keyboardShortcut("P", modifiers: [.command, .shift])
        }

        // Format commands
        CommandMenu("Format") {
            Button("Bold") {
                NotificationCenter.default.post(name: .applyFormat, object: MarkdownFormat.bold)
            }
            .keyboardShortcut("B", modifiers: [.command])

            Button("Italic") {
                NotificationCenter.default.post(name: .applyFormat, object: MarkdownFormat.italic)
            }
            .keyboardShortcut("I", modifiers: [.command])

            Button("Strikethrough") {
                NotificationCenter.default.post(name: .applyFormat, object: MarkdownFormat.strikethrough)
            }

            Divider()

            Button("Inline Code") {
                NotificationCenter.default.post(name: .applyFormat, object: MarkdownFormat.inlineCode)
            }
            .keyboardShortcut("K", modifiers: [.command])

            Button("Code Block") {
                NotificationCenter.default.post(name: .applyFormat, object: MarkdownFormat.codeBlock)
            }
            .keyboardShortcut("K", modifiers: [.command, .shift])

            Divider()

            Button("Link") {
                NotificationCenter.default.post(name: .applyFormat, object: MarkdownFormat.link)
            }
            .keyboardShortcut("L", modifiers: [.command])

            Button("Image") {
                NotificationCenter.default.post(name: .applyFormat, object: MarkdownFormat.image)
            }
            .keyboardShortcut("I", modifiers: [.command, .shift])

            Divider()

            Button("Blockquote") {
                NotificationCenter.default.post(name: .applyFormat, object: MarkdownFormat.blockquote)
            }

            Button("Horizontal Rule") {
                NotificationCenter.default.post(name: .applyFormat, object: MarkdownFormat.horizontalRule)
            }
        }
    }
}

// Notification names for cross-component communication
extension Notification.Name {
    static let changeViewMode = Notification.Name("changeViewMode")
    static let exportHTML = Notification.Name("exportHTML")
    static let exportPDF = Notification.Name("exportPDF")
    static let openFolder = Notification.Name("openFolder")
    static let saveActiveFile = Notification.Name("saveActiveFile")
    static let saveAllFiles = Notification.Name("saveAllFiles")
    static let closeActiveTab = Notification.Name("closeActiveTab")
    static let closeAllTabs = Notification.Name("closeAllTabs")
    static let applyFormat = Notification.Name("applyFormat")
    static let openDroppedFile = Notification.Name("openDroppedFile")
    static let togglePreviewPanel = Notification.Name("togglePreviewPanel")
    static let toggleLogPanel = Notification.Name("toggleLogPanel")
}
