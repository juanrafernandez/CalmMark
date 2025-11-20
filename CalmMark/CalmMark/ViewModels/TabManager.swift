//
//  TabManager.swift
//  CalmMark
//
//  Created by Claude on 2025-11-15.
//

import Foundation
import SwiftUI
import Combine

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
            var content = try String(contentsOf: url, encoding: .utf8)
            var isDirty = false

            // Hot Exit: Check if there's unsaved content
            if let cachedContent = HotExitManager.shared.loadUnsavedContent(for: url) {
                content = cachedContent
                isDirty = true
                LogManager.shared.log(.info, "Restaurado contenido sin guardar desde Hot Exit", context: "TabManager")
            }

            let newFile = OpenFile(url: url, content: content)
            newFile.isDirty = isDirty
            openFiles.append(newFile)
            activeFile = newFile

            // Observar cambios en el contenido para Hot Exit
            setupHotExitObserver(for: newFile)

            LogManager.shared.log(.success, "Archivo abierto exitosamente: \(url.lastPathComponent) (\(content.count) caracteres)", context: "TabManager")
        } catch {
            LogManager.shared.log(.error, "Error al abrir archivo \(url.lastPathComponent): \(error.localizedDescription)", context: "TabManager")
        }
    }

    private func setupHotExitObserver(for file: OpenFile) {
        // Observar cambios en content e isDirty
        file.objectWillChange.sink { [weak self, weak file] _ in
            guard let file = file else { return }
            // Guardar en hot exit cuando cambia el contenido
            DispatchQueue.main.asyncAfter(deadline: .now() + 0.5) {
                HotExitManager.shared.saveUnsavedContent(
                    for: file.url,
                    content: file.content,
                    isDirty: file.isDirty
                )
            }
        }.store(in: &file.cancellables)
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
                // Limpiar hot exit cache cuando el usuario decide no guardar
                HotExitManager.shared.clearCache(for: file.url)
            default: // Cancel
                return
            }
        } else {
            // Si no está dirty, limpiar hot exit cache
            HotExitManager.shared.clearCache(for: file.url)
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
                // Limpiar hot exit cache para todos los archivos dirty
                for file in dirtyFiles {
                    HotExitManager.shared.clearCache(for: file.url)
                }
            default: // Cancel
                return
            }
        }

        // Limpiar hot exit cache para archivos no dirty también
        for file in openFiles where !file.isDirty {
            HotExitManager.shared.clearCache(for: file.url)
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

    func discardAllChanges() {
        LogManager.shared.log(.info, "Descartando todos los cambios sin guardar...", context: "TabManager")

        for file in openFiles where file.isDirty {
            do {
                LogManager.shared.log(.debug, "Recargando \(file.name) desde disco", context: "TabManager")

                // 1. Limpiar Hot Exit cache
                HotExitManager.shared.clearCache(for: file.url)

                // 2. Recargar contenido desde el disco
                try file.reload()

                LogManager.shared.log(.success, "Cambios descartados: \(file.name)", context: "TabManager")
            } catch {
                LogManager.shared.log(.error, "Error recargando \(file.name): \(error)", context: "TabManager")
            }
        }

        LogManager.shared.log(.success, "Todos los cambios descartados exitosamente", context: "TabManager")
    }
}
