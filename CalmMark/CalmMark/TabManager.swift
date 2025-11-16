//
//  TabManager.swift
//  CalmMark
//
//  Created by Claude on 2025-11-15.
//

import Foundation
import SwiftUI
import Combine

// MARK: - Open File Model

class OpenFile: Identifiable, ObservableObject, Equatable {
    let id = UUID()
    let url: URL
    @Published var content: String
    @Published var isDirty: Bool = false
    @Published var isNew: Bool
    var cancellables = Set<AnyCancellable>()

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
        print("💾 [OpenFile.save] GUARDANDO ARCHIVO A DISCO: \(name)")
        print("   📍 Stack trace para debug:")
        Thread.callStackSymbols.forEach { print("      \($0)") }

        try content.write(to: url, atomically: true, encoding: .utf8)
        isDirty = false

        // Limpiar hot exit cache cuando se guarda
        HotExitManager.shared.clearCache(for: url)
        print("✅ [OpenFile.save] Archivo guardado exitosamente")
    }

    func reload() throws {
        content = try String(contentsOf: url, encoding: .utf8)
        isDirty = false

        // Limpiar hot exit cache cuando se recarga
        HotExitManager.shared.clearCache(for: url)
    }
}

// MARK: - Hot Exit Manager

class HotExitManager {
    static let shared = HotExitManager()
    private let userDefaults = UserDefaults.standard
    private let prefix = "hotExit_"

    private init() {}

    func saveUnsavedContent(for url: URL, content: String, isDirty: Bool) {
        guard isDirty else {
            // Si no está dirty, limpiar cualquier cache
            clearCache(for: url)
            return
        }

        let key = hotExitKey(for: url)
        userDefaults.set(content, forKey: key)
        // Log reducido - solo cuando es nuevo o cambio significativo
        // print("💾 [HotExit] Saved unsaved content for: \(url.lastPathComponent)")
    }

    func loadUnsavedContent(for url: URL) -> String? {
        let key = hotExitKey(for: url)
        if let cachedContent = userDefaults.string(forKey: key) {
            print("🔄 [HotExit] Restored unsaved content for: \(url.lastPathComponent)")
            return cachedContent
        }
        return nil
    }

    func clearCache(for url: URL) {
        let key = hotExitKey(for: url)
        userDefaults.removeObject(forKey: key)
        print("🗑️ [HotExit] Cleared cache for: \(url.lastPathComponent)")
    }

    private func hotExitKey(for url: URL) -> String {
        return prefix + url.path
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
}
