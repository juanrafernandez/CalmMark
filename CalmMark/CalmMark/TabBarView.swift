//
//  TabBarView.swift
//  CalmMark
//
//  Created by Claude on 2025-11-15.
//

import SwiftUI

struct TabBarView: View {
    @ObservedObject var tabManager: TabManager

    var body: some View {
        ScrollView(.horizontal, showsIndicators: false) {
            HStack(spacing: 0) {
                ForEach(tabManager.openFiles) { file in
                    TabItemView(
                        file: file,
                        isActive: tabManager.activeFile == file,
                        onSelect: {
                            tabManager.activeFile = file
                        },
                        onClose: {
                            tabManager.closeFile(file)
                        }
                    )
                }
            }
        }
        .frame(height: 32)
        .background(Color(NSColor.controlBackgroundColor))
    }
}

struct TabItemView: View {
    @ObservedObject var file: OpenFile
    let isActive: Bool
    let onSelect: () -> Void
    let onClose: () -> Void

    @State private var isHovered = false

    var body: some View {
        HStack(spacing: 6) {
            // Icon
            Image(systemName: file.url.pathExtension == "md" ? "doc.text" : "doc")
                .font(.system(size: 11))
                .foregroundColor(isActive ? .accentColor : .secondary)

            // File name
            Text(file.displayName)
                .font(.system(size: 12))
                .foregroundColor(isActive ? .primary : .secondary)
                .lineLimit(1)

            // Close button
            if isHovered || isActive {
                Button(action: onClose) {
                    Image(systemName: "xmark")
                        .font(.system(size: 9, weight: .semibold))
                        .foregroundColor(.secondary)
                        .frame(width: 14, height: 14)
                        .background(
                            Circle()
                                .fill(Color.secondary.opacity(0.15))
                        )
                }
                .buttonStyle(.plain)
                .help("Close")
            }
        }
        .padding(.horizontal, 12)
        .padding(.vertical, 6)
        .background(
            RoundedRectangle(cornerRadius: 6, style: .continuous)
                .fill(isActive ? Color(NSColor.controlColor) : Color.clear)
        )
        .overlay(
            RoundedRectangle(cornerRadius: 6, style: .continuous)
                .stroke(isActive ? Color.accentColor.opacity(0.3) : Color.clear, lineWidth: 1)
        )
        .onHover { hovering in
            isHovered = hovering
        }
        .onTapGesture {
            onSelect()
        }
    }
}
