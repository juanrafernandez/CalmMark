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
    var body: some Scene {
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
        }

        // View commands for switching between modes
        CommandMenu("View") {
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
}
