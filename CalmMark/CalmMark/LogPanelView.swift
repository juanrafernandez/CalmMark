//
//  LogPanelView.swift
//  CalmMark
//
//  Created by Claude on 2025-11-15.
//  Panel de logs para debugging
//

import SwiftUI

struct LogPanelView: View {
    @ObservedObject var logManager = LogManager.shared
    @State private var selectedLevel: LogLevel? = nil
    @State private var searchText: String = ""
    @State private var autoScroll: Bool = true

    var filteredLogs: [LogEntry] {
        var logs = logManager.logs

        // Filtrar por nivel
        if let level = selectedLevel {
            logs = logs.filter { $0.level == level }
        }

        // Filtrar por búsqueda
        if !searchText.isEmpty {
            logs = logs.filter {
                $0.message.localizedCaseInsensitiveContains(searchText) ||
                $0.context.localizedCaseInsensitiveContains(searchText)
            }
        }

        return logs
    }

    var body: some View {
        VStack(spacing: 0) {
            // Toolbar
            HStack(spacing: 12) {
                // Título
                HStack(spacing: 4) {
                    Image(systemName: "ladybug.fill")
                        .foregroundColor(.orange)
                    Text("Logs")
                        .font(.system(size: 12, weight: .semibold))

                    if logManager.hasErrors {
                        Image(systemName: "exclamationmark.circle.fill")
                            .foregroundColor(.red)
                    }
                }

                Divider()
                    .frame(height: 16)

                // Filtros por nivel
                HStack(spacing: 4) {
                    ForEach([LogLevel.error, .warning, .info, .debug, .success], id: \.self) { level in
                        Button(action: {
                            if selectedLevel == level {
                                selectedLevel = nil
                            } else {
                                selectedLevel = level
                            }
                        }) {
                            Text(levelIcon(level))
                                .font(.system(size: 10))
                                .padding(.horizontal, 6)
                                .padding(.vertical, 3)
                                .background(selectedLevel == level ? Color.accentColor.opacity(0.2) : Color.clear)
                                .cornerRadius(4)
                        }
                        .buttonStyle(.plain)
                        .help("Filter \(level.rawValue)")
                    }
                }

                Divider()
                    .frame(height: 16)

                // Búsqueda
                HStack(spacing: 4) {
                    Image(systemName: "magnifyingglass")
                        .font(.system(size: 10))
                        .foregroundColor(.secondary)
                    TextField("Search logs...", text: $searchText)
                        .textFieldStyle(.plain)
                        .font(.system(size: 11))
                        .frame(width: 150)
                }
                .padding(.horizontal, 8)
                .padding(.vertical, 4)
                .background(Color(NSColor.controlBackgroundColor))
                .cornerRadius(6)

                Spacer()

                // Controles
                Toggle(isOn: $autoScroll) {
                    Image(systemName: "arrow.down.circle")
                        .font(.system(size: 12))
                }
                .toggleStyle(.button)
                .help("Auto-scroll")

                Button(action: {
                    logManager.clearErrors()
                }) {
                    Image(systemName: "trash.circle")
                        .font(.system(size: 12))
                }
                .buttonStyle(.plain)
                .help("Clear error logs")

                Button(action: {
                    logManager.clearLogs()
                }) {
                    Image(systemName: "xmark.circle")
                        .font(.system(size: 12))
                }
                .buttonStyle(.plain)
                .help("Clear all logs")
            }
            .padding(.horizontal, 12)
            .padding(.vertical, 6)
            .background(Color(NSColor.controlBackgroundColor))

            Divider()

            // Lista de logs
            ScrollViewReader { proxy in
                ScrollView {
                    LazyVStack(alignment: .leading, spacing: 2) {
                        ForEach(filteredLogs) { entry in
                            LogEntryRow(entry: entry)
                                .id(entry.id)
                        }
                    }
                    .padding(8)
                }
                .background(Color(NSColor.textBackgroundColor))
                .onChange(of: logManager.logs.count) { _, _ in
                    if autoScroll, let lastLog = filteredLogs.last {
                        withAnimation {
                            proxy.scrollTo(lastLog.id, anchor: .bottom)
                        }
                    }
                }
            }
        }
    }

    private func levelIcon(_ level: LogLevel) -> String {
        switch level {
        case .debug: return "🔍"
        case .info: return "ℹ️"
        case .warning: return "⚠️"
        case .error: return "❌"
        case .success: return "✅"
        }
    }
}

struct LogEntryRow: View {
    let entry: LogEntry

    var body: some View {
        HStack(alignment: .top, spacing: 8) {
            // Timestamp
            Text(entry.formattedTime)
                .font(.system(size: 10, design: .monospaced))
                .foregroundColor(.secondary)
                .frame(width: 80, alignment: .leading)
                .textSelection(.enabled)

            // Level
            Text(levelIcon(entry.level))
                .font(.system(size: 10))

            // Context
            Text("[\(entry.context)]")
                .font(.system(size: 10, weight: .medium, design: .monospaced))
                .foregroundColor(contextColor(entry.level))
                .frame(minWidth: 80, alignment: .leading)
                .textSelection(.enabled)

            // Message
            Text(entry.message)
                .font(.system(size: 10, design: .monospaced))
                .foregroundColor(messageColor(entry.level))
                .frame(maxWidth: .infinity, alignment: .leading)
                .textSelection(.enabled)

            // Copy button
            Button(action: {
                NSPasteboard.general.clearContents()
                NSPasteboard.general.setString(entry.displayText, forType: .string)
            }) {
                Image(systemName: "doc.on.doc")
                    .font(.system(size: 8))
                    .foregroundColor(.secondary)
            }
            .buttonStyle(.plain)
            .help("Copy log entry")
            .opacity(0.5)
        }
        .padding(.vertical, 2)
        .padding(.horizontal, 4)
        .background(rowBackground(entry.level))
        .cornerRadius(2)
    }

    private func levelIcon(_ level: LogLevel) -> String {
        switch level {
        case .debug: return "🔍"
        case .info: return "ℹ️"
        case .warning: return "⚠️"
        case .error: return "❌"
        case .success: return "✅"
        }
    }

    private func contextColor(_ level: LogLevel) -> Color {
        switch level {
        case .error: return .red
        case .warning: return .orange
        case .success: return .green
        case .info: return .blue
        case .debug: return .secondary
        }
    }

    private func messageColor(_ level: LogLevel) -> Color {
        level == .error ? .red : .primary
    }

    private func rowBackground(_ level: LogLevel) -> Color {
        switch level {
        case .error: return Color.red.opacity(0.05)
        case .warning: return Color.orange.opacity(0.05)
        default: return Color.clear
        }
    }
}
