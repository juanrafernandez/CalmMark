//
//  ContentView.swift
//  CalmMark
//
//  Created by Claude on 2025-11-15.
//

import SwiftUI

struct ContentView: View {
    @Binding var document: CalmMarkDocument
    @StateObject private var settings = AppSettings.shared
    @State private var viewMode: ViewMode = AppSettings.shared.defaultViewMode
    @State private var showExportSheet = false
    @State private var exportType: ExportType = .html

    var body: some View {
        VStack(spacing: 0) {
            // Top toolbar
            ToolbarView(
                viewMode: $viewMode,
                onExportHTML: {
                    exportType = .html
                    showExportSheet = true
                },
                onExportPDF: {
                    exportType = .pdf
                    showExportSheet = true
                }
            )

            Divider()

            // Main content area
            GeometryReader { geometry in
                HStack(spacing: 0) {
                    // Editor
                    if viewMode == .editor || viewMode == .split {
                        EditorView(text: $document.text, settings: settings)
                            .frame(width: viewMode == .split ? geometry.size.width / 2 : geometry.size.width)
                    }

                    // Divider in split mode
                    if viewMode == .split {
                        Divider()
                    }

                    // Preview
                    if viewMode == .preview || viewMode == .split {
                        PreviewView(markdown: document.text, settings: settings)
                            .frame(width: viewMode == .split ? geometry.size.width / 2 : geometry.size.width)
                    }
                }
            }
        }
        .onReceive(NotificationCenter.default.publisher(for: .changeViewMode)) { notification in
            if let mode = notification.object as? ViewMode {
                withAnimation(.easeInOut(duration: 0.2)) {
                    viewMode = mode
                }
            }
        }
        .onReceive(NotificationCenter.default.publisher(for: .exportHTML)) { _ in
            exportType = .html
            showExportSheet = true
        }
        .onReceive(NotificationCenter.default.publisher(for: .exportPDF)) { _ in
            exportType = .pdf
            showExportSheet = true
        }
        .sheet(isPresented: $showExportSheet) {
            ExportView(
                markdown: document.text,
                exportType: exportType,
                settings: settings,
                isPresented: $showExportSheet
            )
        }
    }
}

struct ToolbarView: View {
    @Binding var viewMode: ViewMode
    var onExportHTML: () -> Void
    var onExportPDF: () -> Void

    var body: some View {
        HStack {
            // View mode selector
            Picker("View Mode", selection: $viewMode) {
                ForEach(ViewMode.allCases, id: \.self) { mode in
                    Label(mode.rawValue, systemImage: iconForMode(mode))
                        .tag(mode)
                }
            }
            .pickerStyle(.segmented)
            .frame(maxWidth: 300)
            .padding(.leading, 12)

            Spacer()

            // Export menu
            Menu {
                Button(action: onExportHTML) {
                    Label("Export as HTML", systemImage: "doc.text")
                }

                Button(action: onExportPDF) {
                    Label("Export as PDF", systemImage: "doc.richtext")
                }
            } label: {
                Label("Export", systemImage: "square.and.arrow.up")
                    .padding(.horizontal, 8)
                    .padding(.vertical, 4)
            }
            .menuStyle(.borderlessButton)
            .padding(.trailing, 12)
        }
        .padding(.vertical, 8)
        .background(Color(NSColor.controlBackgroundColor))
    }

    private func iconForMode(_ mode: ViewMode) -> String {
        switch mode {
        case .editor:
            return "doc.text"
        case .preview:
            return "doc.richtext"
        case .split:
            return "rectangle.split.2x1"
        }
    }
}
