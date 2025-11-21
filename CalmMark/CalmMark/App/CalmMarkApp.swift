//
//  CalmMarkApp.swift
//  CalmMark
//
//  Created by Claude on 2025-11-15.
//  A minimalist, native Markdown editor for macOS
//

import SwiftUI
import AppKit

// MARK: - App Launch States

enum AppLaunchState {
    case loading        // Initial loading screen (always shown)
    case initializing   // Splash screen with drag & drop (no content)
    case ready          // Ready to show main content (content exists)
}

@main
struct CalmMarkApp: App {
    @NSApplicationDelegateAdaptor(AppDelegate.self) var appDelegate
    @State private var showDocumentMode = false
    @State private var launchState: AppLaunchState

    // Verificar contenido ANTES de decidir el estado inicial
    init() {
        let hasContent = Self.checkForPreloadedContent()

        if hasContent {
            // Si hay contenido precargado, ir directamente a .ready (sin loading)
            _launchState = State(initialValue: .ready)
            LogManager.shared.log(.info, "App starting directly with content (skip loading)", context: "CalmMarkApp.init")
        } else {
            // Si no hay contenido, mostrar loading screen
            _launchState = State(initialValue: .loading)
            LogManager.shared.log(.info, "App starting with loading screen (no content)", context: "CalmMarkApp.init")
        }
    }

    var body: some Scene {
        // Main Project/Folder mode
        WindowGroup("CalmMark") {
            Group {
                switch launchState {
                case .loading:
                    LoadingView()
                        .onAppear {
                            checkInitialState()
                        }
                case .initializing:
                    SplashScreenView()
                case .ready:
                    ProjectContentView()
                        .environmentObject(appDelegate.tabManagerBridge)
                }
            }
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

    // MARK: - App Initialization

    private func checkInitialState() {
        LogManager.shared.log(.info, "Checking initial state...", context: "CalmMarkApp")

        // Si ya estamos en .ready (contenido precargado), no hacer nada
        if launchState == .ready {
            LogManager.shared.log(.info, "Already in ready state (content preloaded), skipping loading", context: "CalmMarkApp.checkInitialState")
            return
        }

        // Mostrar loading screen brevemente
        let loadingDuration: Double = 0.8

        DispatchQueue.main.asyncAfter(deadline: .now() + loadingDuration) {
            // Verificar si hay contenido previo
            let hasContent = Self.checkForPreloadedContent()

            LogManager.shared.log(
                .info,
                hasContent ? "Content found, loading app..." : "No content, showing splash screen",
                context: "CalmMarkApp.checkInitialState"
            )

            withAnimation(.easeInOut(duration: 0.4)) {
                self.launchState = hasContent ? .ready : .initializing
            }
        }
    }

    // Verificar si hay contenido previamente cargado (método estático para uso en init)
    private static func checkForPreloadedContent() -> Bool {
        let userDefaults = UserDefaults.standard

        // Verificar si hay un bookmark de carpeta guardado
        let hasBookmark = userDefaults.data(forKey: "lastOpenedFolderBookmark") != nil

        // Verificar si hay un archivo activo guardado
        let hasActiveFile = userDefaults.string(forKey: "lastActiveFile") != nil

        LogManager.shared.log(
            .debug,
            "Preloaded content check - Bookmark: \(hasBookmark), Active file: \(hasActiveFile)",
            context: "CalmMarkApp.checkForPreloadedContent"
        )

        return hasBookmark || hasActiveFile
    }
}

// MARK: - App Delegate

class AppDelegate: NSObject, NSApplicationDelegate, ObservableObject {
    let tabManagerBridge = TabManagerBridge()
    private var windowDelegate: ProjectWindowDelegate?

    func applicationDidFinishLaunching(_ notification: Notification) {
        LogManager.shared.log(.info, "Application did finish launching", context: "AppDelegate")

        // Configurar window delegate después de un pequeño delay para que la ventana esté lista
        DispatchQueue.main.asyncAfter(deadline: .now() + 0.5) { [weak self] in
            guard let self = self else { return }
            self.setupWindowDelegate()
        }
    }

    private func setupWindowDelegate() {
        LogManager.shared.log(.debug, "Setting up window delegate... (\(NSApp.windows.count) windows)", context: "AppDelegate")

        // Encontrar la ventana principal (ProjectContentView)
        if let mainWindow = NSApp.windows.first(where: { $0.isMainWindow || $0.isKeyWindow }) {
            LogManager.shared.log(.debug, "Found main window: \(mainWindow.title)", context: "AppDelegate")

            guard let tabManager = tabManagerBridge.tabManager else {
                LogManager.shared.log(.warning, "TabManager not connected yet, will retry...", context: "AppDelegate")
                // Reintentar después de otro delay
                DispatchQueue.main.asyncAfter(deadline: .now() + 0.5) { [weak self] in
                    self?.setupWindowDelegate()
                }
                return
            }

            // Crear y configurar el delegate
            windowDelegate = ProjectWindowDelegate(tabManager: tabManager)
            mainWindow.delegate = windowDelegate
            LogManager.shared.log(.success, "Window delegate configured successfully", context: "AppDelegate")
        } else if let anyWindow = NSApp.windows.first {
            LogManager.shared.log(.debug, "Using first available window: \(anyWindow.title)", context: "AppDelegate")

            guard let tabManager = tabManagerBridge.tabManager else {
                LogManager.shared.log(.warning, "TabManager not connected yet, will retry...", context: "AppDelegate")
                DispatchQueue.main.asyncAfter(deadline: .now() + 0.5) { [weak self] in
                    self?.setupWindowDelegate()
                }
                return
            }

            windowDelegate = ProjectWindowDelegate(tabManager: tabManager)
            anyWindow.delegate = windowDelegate
            LogManager.shared.log(.success, "Window delegate configured successfully", context: "AppDelegate")
        } else {
            LogManager.shared.log(.error, "No windows found", context: "AppDelegate")
        }
    }

    // Hacer que la app se cierre cuando se cierra la última ventana
    func applicationShouldTerminateAfterLastWindowClosed(_ sender: NSApplication) -> Bool {
        LogManager.shared.log(.info, "Last window closed, app will terminate", context: "AppDelegate")
        return true
    }

    func applicationShouldTerminate(_ sender: NSApplication) -> NSApplication.TerminateReply {
        LogManager.shared.log(.info, "applicationShouldTerminate called", context: "AppDelegate")

        // Verificar si hay archivos con cambios sin guardar
        guard let tabManager = tabManagerBridge.tabManager else {
            LogManager.shared.log(.warning, "TabManager is nil, terminating immediately", context: "AppDelegate")
            return .terminateNow
        }

        let dirtyFiles = tabManager.openFiles.filter { $0.isDirty }
        LogManager.shared.log(.debug, "Found \(dirtyFiles.count) dirty files out of \(tabManager.openFiles.count) total", context: "AppDelegate")

        if dirtyFiles.isEmpty {
            LogManager.shared.log(.info, "No dirty files, terminating", context: "AppDelegate")
            return .terminateNow
        }

        // Mostrar diálogo al usuario
        LogManager.shared.log(.info, "Showing quit confirmation dialog", context: "AppDelegate")
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
            LogManager.shared.log(.info, "User chose: Save All", context: "AppDelegate")
            tabManager.saveAllFiles()
            return .terminateNow
        case .alertSecondButtonReturn: // Don't Save
            LogManager.shared.log(.info, "User chose: Don't Save", context: "AppDelegate")
            // Limpiar Hot Exit cache y recargar archivos desde el disco
            tabManager.discardAllChanges()
            return .terminateNow
        default: // Cancel
            LogManager.shared.log(.info, "User chose: Cancel", context: "AppDelegate")
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
        LogManager.shared.log(.info, "Window close requested", context: "WindowDelegate")

        guard let tabManager = tabManager else {
            LogManager.shared.log(.warning, "TabManager is nil, allowing close", context: "WindowDelegate")
            return true
        }

        let dirtyFiles = tabManager.openFiles.filter { $0.isDirty }
        LogManager.shared.log(.debug, "Found \(dirtyFiles.count) dirty files out of \(tabManager.openFiles.count) total", context: "WindowDelegate")

        if dirtyFiles.isEmpty {
            LogManager.shared.log(.info, "No dirty files, allowing close", context: "WindowDelegate")
            return true
        }

        // Mostrar diálogo al usuario
        LogManager.shared.log(.info, "Showing close confirmation dialog", context: "WindowDelegate")
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
            LogManager.shared.log(.info, "User chose: Save All", context: "WindowDelegate")
            tabManager.saveAllFiles()
            return true
        case .alertSecondButtonReturn: // Don't Save
            LogManager.shared.log(.info, "User chose: Don't Save", context: "WindowDelegate")
            // Limpiar Hot Exit cache y recargar archivos desde el disco
            tabManager.discardAllChanges()
            return true
        default: // Cancel
            LogManager.shared.log(.info, "User chose: Cancel", context: "WindowDelegate")
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

// MARK: - Loading View

struct LoadingView: View {
    @State private var isAnimating = false

    var body: some View {
        VStack(spacing: 20) {
            // Simple animated logo
            Image(systemName: "leaf.fill")
                .font(.system(size: 60))
                .foregroundStyle(
                    LinearGradient(
                        colors: [.green, .mint],
                        startPoint: .topLeading,
                        endPoint: .bottomTrailing
                    )
                )
                .opacity(isAnimating ? 1.0 : 0.3)
                .scaleEffect(isAnimating ? 1.0 : 0.8)

            // Loading indicator
            ProgressView()
                .scaleEffect(1.0)
                .opacity(0.8)
        }
        .frame(maxWidth: .infinity, maxHeight: .infinity)
        .background(Color(NSColor.textBackgroundColor))
        .onAppear {
            withAnimation(.easeInOut(duration: 0.6).repeatForever(autoreverses: true)) {
                isAnimating = true
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
