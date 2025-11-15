//
//  CalmMarkApp.swift
//  CalmMark
//
//  Created by Claude on 2025-11-15.
//  A minimalist, native Markdown editor for macOS
//

import SwiftUI

@main
struct CalmMarkApp: App {
    @State private var showDocumentMode = false

    var body: some Scene {
        // Main Project/Folder mode
        WindowGroup("CalmMark") {
            ProjectContentView()
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
}
