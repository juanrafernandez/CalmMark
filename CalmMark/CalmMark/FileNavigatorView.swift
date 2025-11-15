//
//  FileNavigatorView.swift
//  CalmMark
//
//  Created by Claude on 2025-11-15.
//

import SwiftUI

struct FileNavigatorView: View {
    @ObservedObject var fileManager: FileSystemManager
    @Binding var openFiles: [OpenFile]
    @Binding var activeFile: OpenFile?

    var body: some View {
        VStack(spacing: 0) {
            // Header
            HStack {
                Text("PROJECT")
                    .font(.caption)
                    .fontWeight(.semibold)
                    .foregroundColor(.secondary)

                Spacer()

                Menu {
                    Button(action: {
                        fileManager.openFolder()
                    }) {
                        Label("Open Folder...", systemImage: "folder.badge.plus")
                    }

                    Divider()

                    if let root = fileManager.rootFolder {
                        Button(action: {
                            createNewFile(in: root)
                        }) {
                            Label("New File...", systemImage: "doc.badge.plus")
                        }

                        Button(action: {
                            createNewFolder(in: root)
                        }) {
                            Label("New Folder...", systemImage: "folder.badge.plus")
                        }

                        Divider()

                        Button(action: {
                            fileManager.revealInFinder(root)
                        }) {
                            Label("Reveal in Finder", systemImage: "folder")
                        }
                    }
                } label: {
                    Image(systemName: "ellipsis.circle")
                        .font(.system(size: 14))
                }
                .menuStyle(.borderlessButton)
            }
            .padding(.horizontal, 12)
            .padding(.vertical, 8)
            .background(Color(NSColor.controlBackgroundColor))

            Divider()

            // File tree
            if let root = fileManager.rootFolder {
                ScrollView {
                    VStack(alignment: .leading, spacing: 2) {
                        FileTreeItemView(
                            item: root,
                            fileManager: fileManager,
                            openFiles: $openFiles,
                            activeFile: $activeFile,
                            level: 0
                        )
                    }
                    .padding(.vertical, 8)
                }
            } else {
                // Empty state
                VStack(spacing: 16) {
                    Image(systemName: "folder.badge.questionmark")
                        .font(.system(size: 48))
                        .foregroundColor(.secondary)

                    Text("No Folder Open")
                        .font(.headline)
                        .foregroundColor(.secondary)

                    Button("Open Folder...") {
                        fileManager.openFolder()
                    }
                    .buttonStyle(.borderedProminent)
                }
                .frame(maxWidth: .infinity, maxHeight: .infinity)
            }
        }
        .frame(maxHeight: .infinity)
    }

    private func createNewFile(in folder: FileItem) {
        let alert = NSAlert()
        alert.messageText = "New File"
        alert.informativeText = "Enter the name for the new file:"
        alert.addButton(withTitle: "Create")
        alert.addButton(withTitle: "Cancel")

        let textField = NSTextField(frame: NSRect(x: 0, y: 0, width: 200, height: 24))
        textField.stringValue = "untitled.md"
        alert.accessoryView = textField

        if alert.runModal() == .alertFirstButtonReturn {
            let name = textField.stringValue
            _ = fileManager.createNewFile(in: folder, name: name)
        }
    }

    private func createNewFolder(in folder: FileItem) {
        let alert = NSAlert()
        alert.messageText = "New Folder"
        alert.informativeText = "Enter the name for the new folder:"
        alert.addButton(withTitle: "Create")
        alert.addButton(withTitle: "Cancel")

        let textField = NSTextField(frame: NSRect(x: 0, y: 0, width: 200, height: 24))
        textField.stringValue = "New Folder"
        alert.accessoryView = textField

        if alert.runModal() == .alertFirstButtonReturn {
            let name = textField.stringValue
            _ = fileManager.createNewFolder(in: folder, name: name)
        }
    }
}

// MARK: - File Tree Item View

struct FileTreeItemView: View {
    @ObservedObject var item: FileItem
    @ObservedObject var fileManager: FileSystemManager
    @Binding var openFiles: [OpenFile]
    @Binding var activeFile: OpenFile?
    let level: Int

    @State private var isHovered = false

    var body: some View {
        VStack(alignment: .leading, spacing: 2) {
            // Item row
            HStack(spacing: 4) {
                // Indentation
                Color.clear
                    .frame(width: CGFloat(level * 16))

                // Disclosure arrow (for directories)
                if item.isDirectory {
                    Button(action: {
                        withAnimation(.easeInOut(duration: 0.15)) {
                            item.isExpanded.toggle()
                            if item.isExpanded {
                                item.loadChildren()
                            }
                        }
                    }) {
                        Image(systemName: "chevron.right")
                            .font(.system(size: 10, weight: .semibold))
                            .rotationEffect(.degrees(item.isExpanded ? 90 : 0))
                            .frame(width: 12, height: 12)
                    }
                    .buttonStyle(.plain)
                } else {
                    Color.clear.frame(width: 12)
                }

                // Icon
                Image(systemName: item.icon)
                    .font(.system(size: 13))
                    .foregroundColor(Color(item.iconColor))
                    .frame(width: 16)

                // Name
                Text(item.name)
                    .font(.system(size: 12))
                    .foregroundColor(isSelected ? .white : .primary)
                    .lineLimit(1)

                // Badge for Claude commands
                if item.isClaudeCommand {
                    Image(systemName: "command")
                        .font(.system(size: 9))
                        .foregroundColor(.purple)
                }

                Spacer()
            }
            .padding(.horizontal, 8)
            .padding(.vertical, 4)
            .background(
                RoundedRectangle(cornerRadius: 4)
                    .fill(isSelected ? Color.accentColor : (isHovered ? Color.secondary.opacity(0.1) : Color.clear))
            )
            .onHover { hovering in
                isHovered = hovering
            }
            .onTapGesture {
                handleTap()
            }
            .contextMenu {
                contextMenuItems
            }

            // Children (if expanded)
            if item.isDirectory && item.isExpanded {
                ForEach(item.children) { child in
                    FileTreeItemView(
                        item: child,
                        fileManager: fileManager,
                        openFiles: $openFiles,
                        activeFile: $activeFile,
                        level: level + 1
                    )
                }
            }
        }
    }

    private var isSelected: Bool {
        activeFile?.url == item.url
    }

    private func handleTap() {
        if item.isDirectory {
            withAnimation(.easeInOut(duration: 0.15)) {
                item.isExpanded.toggle()
                if item.isExpanded {
                    item.loadChildren()
                }
            }
        } else if item.isMarkdown {
            openFile(item)
        }
    }

    private func openFile(_ item: FileItem) {
        // Check if already open
        if let existingFile = openFiles.first(where: { $0.url == item.url }) {
            activeFile = existingFile
        } else {
            // Load file content
            do {
                let content = try String(contentsOf: item.url, encoding: .utf8)
                let newFile = OpenFile(url: item.url, content: content)
                openFiles.append(newFile)
                activeFile = newFile
            } catch {
                print("Error opening file: \(error)")
            }
        }
    }

    private var contextMenuItems: some View {
        Group {
            if !item.isDirectory {
                Button("Open") {
                    openFile(item)
                }
            }

            Button("Reveal in Finder") {
                fileManager.revealInFinder(item)
            }

            Divider()

            if item.isDirectory {
                Button("New File...") {
                    // TODO: Implement
                }

                Button("New Folder...") {
                    // TODO: Implement
                }
            }

            Divider()

            Button("Copy Path") {
                NSPasteboard.general.clearContents()
                NSPasteboard.general.setString(item.url.path, forType: .string)
            }
        }
    }
}
