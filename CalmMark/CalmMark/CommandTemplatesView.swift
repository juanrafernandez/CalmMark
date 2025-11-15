//
//  CommandTemplatesView.swift
//  CalmMark
//
//  Created by Claude on 2025-11-15.
//

import SwiftUI

struct CommandTemplatesView: View {
    let fileManager: FileSystemManager
    @Binding var isPresented: Bool

    @State private var selectedCategory: TemplateCategory = .code
    @State private var selectedTemplate: CommandTemplate?
    @State private var showingVariables = false

    private let templateManager = CommandTemplateManager.shared

    var body: some View {
        VStack(spacing: 0) {
            // Header
            HStack {
                Image(systemName: "terminal.fill")
                    .font(.title2)
                    .foregroundColor(.purple)

                Text("AI Command Templates")
                    .font(.title2)
                    .fontWeight(.semibold)

                Spacer()

                Button("Done") {
                    isPresented = false
                }
                .keyboardShortcut(.cancelAction)
            }
            .padding()

            Divider()

            HSplitView {
                // Category sidebar
                VStack(alignment: .leading, spacing: 0) {
                    Text("CATEGORIES")
                        .font(.caption)
                        .fontWeight(.semibold)
                        .foregroundColor(.secondary)
                        .padding(.horizontal, 12)
                        .padding(.vertical, 8)

                    ForEach(TemplateCategory.allCases, id: \.self) { category in
                        CategoryRow(
                            category: category,
                            isSelected: selectedCategory == category,
                            count: templateManager.getTemplatesByCategory(category).count
                        )
                        .onTapGesture {
                            selectedCategory = category
                            selectedTemplate = nil
                        }
                    }

                    Spacer()
                }
                .frame(minWidth: 150, idealWidth: 180, maxWidth: 200)
                .background(Color(NSColor.controlBackgroundColor))

                // Templates list
                VStack(alignment: .leading, spacing: 0) {
                    Text("TEMPLATES")
                        .font(.caption)
                        .fontWeight(.semibold)
                        .foregroundColor(.secondary)
                        .padding(.horizontal, 12)
                        .padding(.vertical, 8)

                    ScrollView {
                        VStack(spacing: 8) {
                            ForEach(templateManager.getTemplatesByCategory(selectedCategory)) { template in
                                TemplateCard(
                                    template: template,
                                    isSelected: selectedTemplate?.id == template.id
                                )
                                .onTapGesture {
                                    selectedTemplate = template
                                }
                            }
                        }
                        .padding(12)
                    }
                }
                .frame(minWidth: 250, idealWidth: 300)

                // Template preview/create
                if let template = selectedTemplate {
                    TemplateDetailView(
                        template: template,
                        fileManager: fileManager,
                        onCreated: {
                            isPresented = false
                        }
                    )
                    .frame(minWidth: 350, idealWidth: 450)
                } else {
                    EmptyTemplateView()
                        .frame(minWidth: 350, idealWidth: 450)
                }
            }
        }
        .frame(width: 900, height: 600)
    }
}

// MARK: - Category Row

struct CategoryRow: View {
    let category: TemplateCategory
    let isSelected: Bool
    let count: Int

    var body: some View {
        HStack {
            Image(systemName: iconForCategory)
                .font(.system(size: 14))
                .foregroundColor(isSelected ? .accentColor : .secondary)
                .frame(width: 20)

            Text(category.rawValue)
                .font(.system(size: 13))
                .foregroundColor(isSelected ? .primary : .secondary)

            Spacer()

            Text("\(count)")
                .font(.system(size: 11))
                .foregroundColor(.secondary)
        }
        .padding(.horizontal, 12)
        .padding(.vertical, 8)
        .background(
            RoundedRectangle(cornerRadius: 6)
                .fill(isSelected ? Color.accentColor.opacity(0.1) : Color.clear)
        )
        .padding(.horizontal, 8)
    }

    private var iconForCategory: String {
        switch category {
        case .code: return "chevron.left.forwardslash.chevron.right"
        case .documentation: return "doc.text"
        case .testing: return "checkmark.seal"
        case .git: return "arrow.triangle.branch"
        case .custom: return "star"
        }
    }
}

// MARK: - Template Card

struct TemplateCard: View {
    let template: CommandTemplate
    let isSelected: Bool

    var body: some View {
        VStack(alignment: .leading, spacing: 8) {
            HStack {
                Text(template.name)
                    .font(.system(size: 14, weight: .semibold))
                    .foregroundColor(isSelected ? .accentColor : .primary)

                Spacer()

                Image(systemName: "chevron.right")
                    .font(.system(size: 10))
                    .foregroundColor(.secondary)
            }

            Text(template.description)
                .font(.system(size: 12))
                .foregroundColor(.secondary)
                .lineLimit(2)
        }
        .padding(12)
        .background(
            RoundedRectangle(cornerRadius: 8)
                .fill(isSelected ? Color.accentColor.opacity(0.05) : Color(NSColor.controlBackgroundColor))
        )
        .overlay(
            RoundedRectangle(cornerRadius: 8)
                .stroke(isSelected ? Color.accentColor : Color.clear, lineWidth: 2)
        )
    }
}

// MARK: - Template Detail View

struct TemplateDetailView: View {
    let template: CommandTemplate
    let fileManager: FileSystemManager
    let onCreated: () -> Void

    @State private var filename: String = ""
    @State private var showAlert = false
    @State private var alertMessage = ""

    var body: some View {
        VStack(alignment: .leading, spacing: 16) {
            // Header
            HStack {
                Image(systemName: "doc.text.fill")
                    .font(.title)
                    .foregroundColor(.accentColor)

                VStack(alignment: .leading, spacing: 4) {
                    Text(template.name)
                        .font(.title3)
                        .fontWeight(.semibold)

                    Text(template.description)
                        .font(.caption)
                        .foregroundColor(.secondary)
                }

                Spacer()
            }
            .padding()
            .background(Color(NSColor.controlBackgroundColor))
            .cornerRadius(8)

            // Filename input
            VStack(alignment: .leading, spacing: 8) {
                Text("Filename")
                    .font(.caption)
                    .fontWeight(.semibold)

                TextField("command-name.md", text: $filename)
                    .textFieldStyle(.roundedBorder)
            }

            // Preview
            VStack(alignment: .leading, spacing: 8) {
                Text("Template Preview")
                    .font(.caption)
                    .fontWeight(.semibold)

                ScrollView {
                    Text(template.content)
                        .font(.system(size: 11, design: .monospaced))
                        .padding(12)
                        .frame(maxWidth: .infinity, alignment: .leading)
                        .background(Color(NSColor.textBackgroundColor))
                        .cornerRadius(6)
                }
            }

            Spacer()

            // Actions
            HStack {
                Button("Cancel") {
                    onCreated()
                }

                Spacer()

                Button("Create Command") {
                    createCommand()
                }
                .buttonStyle(.borderedProminent)
                .disabled(filename.isEmpty || fileManager.rootFolder == nil)
            }
        }
        .padding()
        .onAppear {
            filename = template.filename
        }
        .alert("Command File", isPresented: $showAlert) {
            Button("OK") {
                if alertMessage.contains("success") {
                    onCreated()
                }
            }
        } message: {
            Text(alertMessage)
        }
    }

    private func createCommand() {
        guard let root = fileManager.rootFolder else {
            alertMessage = "No folder is open."
            showAlert = true
            return
        }

        do {
            let commandsDir = try CommandTemplateManager.getCommandsDirectory(in: root.url)

            let finalFilename = filename.hasSuffix(".md") ? filename : "\(filename).md"
            let fileURL = commandsDir.appendingPathComponent(finalFilename)

            // Check if file exists
            if FileManager.default.fileExists(atPath: fileURL.path) {
                alertMessage = "A file with this name already exists."
                showAlert = true
                return
            }

            // Create file
            try template.content.write(to: fileURL, atomically: true, encoding: .utf8)

            // Reload file tree
            if let claudeFolder = root.children.first(where: { $0.name == ".claude" }) {
                claudeFolder.loadChildren()
                if let commandsFolder = claudeFolder.children.first(where: { $0.name == "commands" }) {
                    commandsFolder.loadChildren()
                }
            } else {
                root.loadChildren()
            }

            alertMessage = "Command file created successfully at:\n.claude/commands/\(finalFilename)"
            showAlert = true

        } catch {
            alertMessage = "Error creating command file: \(error.localizedDescription)"
            showAlert = true
        }
    }
}

// MARK: - Empty Template View

struct EmptyTemplateView: View {
    var body: some View {
        VStack(spacing: 16) {
            Image(systemName: "doc.text.magnifyingglass")
                .font(.system(size: 64))
                .foregroundColor(.secondary)

            Text("Select a template")
                .font(.headline)
                .foregroundColor(.secondary)

            Text("Choose a template from the list to see details and create a new command file.")
                .font(.caption)
                .foregroundColor(.secondary)
                .multilineTextAlignment(.center)
                .frame(maxWidth: 300)
        }
        .frame(maxWidth: .infinity, maxHeight: .infinity)
    }
}
