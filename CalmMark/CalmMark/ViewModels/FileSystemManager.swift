//
//  FileSystemManager.swift
//  CalmMark
//
//  Created by Claude on 2025-11-15.
//

import Foundation
import AppKit

// MARK: - File System Manager

class FileSystemManager: ObservableObject {
    @Published var rootFolder: FileItem?
    @Published var selectedFile: FileItem?

    // Open folder
    func openFolder() {
        let panel = NSOpenPanel()
        panel.title = "Open Folder"
        panel.canChooseFiles = false
        panel.canChooseDirectories = true
        panel.canCreateDirectories = false
        panel.allowsMultipleSelection = false

        panel.begin { [weak self] response in
            guard response == .OK, let url = panel.url else { return }
            self?.setRootFolder(url)
        }
    }

    func setRootFolder(_ url: URL) {
        let root = FileItem(url: url)
        root.isExpanded = true
        root.loadChildren()
        rootFolder = root

        // Guardar bookmark con permisos persistentes
        saveBookmark(for: url)
    }

    // MARK: - Bookmark Persistence

    private func saveBookmark(for url: URL) {
        do {
            // Crear security-scoped bookmark
            let bookmarkData = try url.bookmarkData(
                options: .withSecurityScope,
                includingResourceValuesForKeys: nil,
                relativeTo: nil
            )

            // Guardar en UserDefaults
            UserDefaults.standard.set(bookmarkData, forKey: "lastOpenedFolderBookmark")
            UserDefaults.standard.set(url.path, forKey: "lastOpenedFolder")
            LogManager.shared.log(.success, "Bookmark guardado: \(url.path)", context: "FileSystemManager")
        } catch {
            LogManager.shared.log(.error, "Error creando bookmark: \(error)", context: "FileSystemManager")
        }
    }

    func restoreLastFolder() -> Bool {
        // Intentar restaurar desde bookmark
        guard let bookmarkData = UserDefaults.standard.data(forKey: "lastOpenedFolderBookmark") else {
            LogManager.shared.log(.debug, "No se encontró bookmark guardado", context: "FileSystemManager")
            return false
        }

        do {
            var isStale = false
            let url = try URL(
                resolvingBookmarkData: bookmarkData,
                options: .withSecurityScope,
                relativeTo: nil,
                bookmarkDataIsStale: &isStale
            )

            // Iniciar acceso con security scope
            guard url.startAccessingSecurityScopedResource() else {
                LogManager.shared.log(.error, "Fallo al acceder al recurso con security scope", context: "FileSystemManager")
                return false
            }

            // Cargar la carpeta
            setRootFolder(url)

            // Si el bookmark está obsoleto, recrearlo
            if isStale {
                LogManager.shared.log(.warning, "Bookmark obsoleto, recreando...", context: "FileSystemManager")
                saveBookmark(for: url)
            }

            LogManager.shared.log(.success, "Carpeta restaurada desde bookmark: \(url.path)", context: "FileSystemManager")
            return true
        } catch {
            LogManager.shared.log(.error, "Error restaurando bookmark: \(error)", context: "FileSystemManager")
            return false
        }
    }

    // Get all markdown files in project
    func getAllMarkdownFiles() -> [FileItem] {
        guard let root = rootFolder else { return [] }
        var markdownFiles: [FileItem] = []

        func traverse(_ item: FileItem) {
            if item.isMarkdown {
                markdownFiles.append(item)
            }
            if item.isDirectory {
                item.loadChildren()
                for child in item.children {
                    traverse(child)
                }
            }
        }

        traverse(root)
        return markdownFiles
    }

    // Get Claude command files
    func getClaudeCommandFiles() -> [FileItem] {
        getAllMarkdownFiles().filter { $0.isClaudeCommand }
    }

    // Create new file
    func createNewFile(in folder: FileItem, name: String, content: String = "") -> Bool {
        guard folder.isDirectory else { return false }

        let newFileURL = folder.url.appendingPathComponent(name)

        do {
            try content.write(to: newFileURL, atomically: true, encoding: .utf8)
            folder.loadChildren()
            LogManager.shared.log(.success, "Archivo creado: \(name)", context: "FileSystemManager")
            return true
        } catch {
            LogManager.shared.log(.error, "Error creando archivo: \(error)", context: "FileSystemManager")
            return false
        }
    }

    // Create new folder
    func createNewFolder(in folder: FileItem, name: String) -> Bool {
        guard folder.isDirectory else { return false }

        let newFolderURL = folder.url.appendingPathComponent(name)

        do {
            try FileManager.default.createDirectory(
                at: newFolderURL,
                withIntermediateDirectories: false
            )
            folder.loadChildren()
            LogManager.shared.log(.success, "Carpeta creada: \(name)", context: "FileSystemManager")
            return true
        } catch {
            LogManager.shared.log(.error, "Error creando carpeta: \(error)", context: "FileSystemManager")
            return false
        }
    }

    // Reveal in Finder
    func revealInFinder(_ item: FileItem) {
        NSWorkspace.shared.activateFileViewerSelecting([item.url])
    }
}
