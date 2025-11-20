//
//  ExportView.swift
//  CalmMark
//
//  Created by Claude on 2025-11-15.
//

import SwiftUI
import AppKit

struct ExportView: View {
    let markdown: String
    let exportType: ExportType
    let settings: AppSettings
    @Binding var isPresented: Bool

    @State private var showAlert = false
    @State private var alertMessage = ""

    var body: some View {
        VStack(spacing: 20) {
            Image(systemName: exportType == .html ? "doc.text" : "doc.richtext")
                .font(.system(size: 60))
                .foregroundColor(.accentColor)

            Text("Export as \(exportType == .html ? "HTML" : "PDF")")
                .font(.title2)
                .fontWeight(.semibold)

            Text("Choose where to save your \(exportType == .html ? "HTML" : "PDF") file.")
                .font(.body)
                .foregroundColor(.secondary)
                .multilineTextAlignment(.center)

            HStack(spacing: 12) {
                Button("Cancel") {
                    isPresented = false
                }
                .keyboardShortcut(.cancelAction)

                Button("Export") {
                    performExport()
                }
                .keyboardShortcut(.defaultAction)
            }
            .padding(.top, 8)
        }
        .padding(30)
        .frame(width: 400)
        .alert("Export Status", isPresented: $showAlert) {
            Button("OK") {
                if alertMessage.contains("success") {
                    isPresented = false
                }
            }
        } message: {
            Text(alertMessage)
        }
        .onAppear {
            // Auto-trigger save panel on appear
            DispatchQueue.main.asyncAfter(deadline: .now() + 0.3) {
                performExport()
            }
        }
    }

    private func performExport() {
        let savePanel = NSSavePanel()
        savePanel.title = "Export \(exportType == .html ? "HTML" : "PDF")"
        savePanel.nameFieldStringValue = ExportManager.suggestedFileName(for: exportType)
        savePanel.canCreateDirectories = true

        if exportType == .html {
            savePanel.allowedContentTypes = [.html]
        } else {
            savePanel.allowedContentTypes = [.pdf]
        }

        savePanel.begin { response in
            if response == .OK, let url = savePanel.url {
                switch exportType {
                case .html:
                    let success = ExportManager.exportHTML(
                        markdown: markdown,
                        settings: settings,
                        to: url
                    )
                    if success {
                        alertMessage = "HTML exported successfully!"
                        showAlert = true
                    } else {
                        alertMessage = "Failed to export HTML."
                        showAlert = true
                    }

                case .pdf:
                    ExportManager.exportPDF(
                        markdown: markdown,
                        settings: settings,
                        to: url
                    ) { success in
                        if success {
                            alertMessage = "PDF exported successfully!"
                        } else {
                            alertMessage = "Failed to export PDF."
                        }
                        showAlert = true
                    }
                }
            } else {
                // User cancelled
                isPresented = false
            }
        }
    }
}
