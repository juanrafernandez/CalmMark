//
//  TabManager.swift
//  CalmMark
//
//  Created by Claude on 2025-11-15.
//

import Foundation
import SwiftUI

// MARK: - Open File Model

class OpenFile: Identifiable, ObservableObject, Equatable {
    let id = UUID()
    let url: URL
    @Published var content: String
    @Published var isDirty: Bool = false
    @Published var isNew: Bool

    var name: String {
        url.lastPathComponent
    }

    var displayName: String {
        isDirty ? "\(name) •" : name
    }

    init(url: URL, content: String, isNew: Bool = false) {
        self.url = url
        self.content = content
        self.isNew = isNew
    }

    static func == (lhs: OpenFile, rhs: OpenFile) -> Bool {
        lhs.id == rhs.id
    }

    func save() throws {
        try content.write(to: url, atomically: true, encoding: .utf8)
        isDirty = false
    }

    func reload() throws {
        content = try String(contentsOf: url, encoding: .utf8)
        isDirty = false
    }
}

// MARK: - Tab Manager

class TabManager: ObservableObject {
    @Published var openFiles: [OpenFile] = []
    @Published var activeFile: OpenFile?

    func openFile(url: URL) {
        LogManager.shared.log(.info, "Abriendo archivo: \(url.lastPathComponent)", context: "TabManager")

        // Check if already open
        if let existingFile = openFiles.first(where: { $0.url == url }) {
            LogManager.shared.log(.debug, "Archivo ya estaba abierto, activándolo", context: "TabManager")
            activeFile = existingFile
            return
        }

        // Load and open
        do {
            let content = try String(contentsOf: url, encoding: .utf8)
            let newFile = OpenFile(url: url, content: content)
            openFiles.append(newFile)
            activeFile = newFile
            LogManager.shared.log(.success, "Archivo abierto exitosamente: \(url.lastPathComponent) (\(content.count) caracteres)", context: "TabManager")
        } catch {
            LogManager.shared.log(.error, "Error al abrir archivo \(url.lastPathComponent): \(error.localizedDescription)", context: "TabManager")
        }
    }

    func closeFile(_ file: OpenFile) {
        if file.isDirty {
            // Show save dialog
            let alert = NSAlert()
            alert.messageText = "Save changes?"
            alert.informativeText = "The file \"\(file.name)\" has unsaved changes."
            alert.addButton(withTitle: "Save")
            alert.addButton(withTitle: "Don't Save")
            alert.addButton(withTitle: "Cancel")

            let response = alert.runModal()

            switch response {
            case .alertFirstButtonReturn: // Save
                do {
                    try file.save()
                } catch {
                    print("Error saving file: \(error)")
                    return
                }
            case .alertSecondButtonReturn: // Don't Save
                break
            default: // Cancel
                return
            }
        }

        // Remove from array
        if let index = openFiles.firstIndex(of: file) {
            openFiles.remove(at: index)

            // Switch to next tab if this was active
            if activeFile == file {
                if index < openFiles.count {
                    activeFile = openFiles[index]
                } else if !openFiles.isEmpty {
                    activeFile = openFiles.last
                } else {
                    activeFile = nil
                }
            }
        }
    }

    func closeAllFiles() {
        // Check for dirty files
        let dirtyFiles = openFiles.filter { $0.isDirty }

        if !dirtyFiles.isEmpty {
            let alert = NSAlert()
            alert.messageText = "Save all changes?"
            alert.informativeText = "\(dirtyFiles.count) file(s) have unsaved changes."
            alert.addButton(withTitle: "Save All")
            alert.addButton(withTitle: "Don't Save")
            alert.addButton(withTitle: "Cancel")

            let response = alert.runModal()

            switch response {
            case .alertFirstButtonReturn: // Save All
                for file in dirtyFiles {
                    do {
                        try file.save()
                    } catch {
                        print("Error saving file: \(error)")
                    }
                }
            case .alertSecondButtonReturn: // Don't Save
                break
            default: // Cancel
                return
            }
        }

        openFiles.removeAll()
        activeFile = nil
    }

    func saveActiveFile() {
        guard let file = activeFile else { return }

        do {
            try file.save()
        } catch {
            print("Error saving file: \(error)")

            let alert = NSAlert()
            alert.messageText = "Save Failed"
            alert.informativeText = "Could not save \"\(file.name)\": \(error.localizedDescription)"
            alert.alertStyle = .warning
            alert.runModal()
        }
    }

    func saveAllFiles() {
        for file in openFiles where file.isDirty {
            do {
                try file.save()
            } catch {
                print("Error saving file \(file.name): \(error)")
            }
        }
    }
}
