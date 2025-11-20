//
//  OutlinePanelView.swift
//  CalmMark
//
//  Shows document outline with clickable headings for navigation
//

import SwiftUI

struct OutlinePanelView: View {
    let headings: [HeadingItem]
    let onHeadingClick: (Int) -> Void

    @State private var hoveredHeading: UUID? = nil

    var body: some View {
        VStack(alignment: .leading, spacing: 0) {
            // Header
            HStack {
                Image(systemName: "list.bullet.indent")
                    .font(.system(size: 14, weight: .medium))
                    .foregroundColor(.secondary)

                Text("Outline")
                    .font(.system(size: 13, weight: .semibold))
                    .foregroundColor(.primary)

                Spacer()

                Text("\(headings.count)")
                    .font(.system(size: 11, weight: .medium))
                    .foregroundColor(.secondary)
                    .padding(.horizontal, 6)
                    .padding(.vertical, 2)
                    .background(Color.secondary.opacity(0.1))
                    .cornerRadius(8)
            }
            .padding(.horizontal, 12)
            .padding(.vertical, 10)
            .background(Color(nsColor: .controlBackgroundColor))

            Divider()

            // Headings list
            if headings.isEmpty {
                VStack(spacing: 8) {
                    Image(systemName: "doc.text")
                        .font(.system(size: 32))
                        .foregroundColor(.secondary.opacity(0.5))

                    Text("No headings found")
                        .font(.system(size: 12))
                        .foregroundColor(.secondary)
                }
                .frame(maxWidth: .infinity, maxHeight: .infinity)
                .padding()
            } else {
                ScrollView {
                    LazyVStack(alignment: .leading, spacing: 2) {
                        ForEach(headings) { heading in
                            HeadingRow(
                                heading: heading,
                                isHovered: hoveredHeading == heading.id,
                                onHover: { isHovered in
                                    hoveredHeading = isHovered ? heading.id : nil
                                },
                                onClick: {
                                    onHeadingClick(heading.lineNumber)
                                }
                            )
                        }
                    }
                    .padding(.vertical, 8)
                }
            }
        }
        .frame(minWidth: 200, maxWidth: 300)
        .background(Color(nsColor: .textBackgroundColor))
    }
}

// MARK: - Heading Row

private struct HeadingRow: View {
    let heading: HeadingItem
    let isHovered: Bool
    let onHover: (Bool) -> Void
    let onClick: () -> Void

    var body: some View {
        Button(action: onClick) {
            HStack(alignment: .top, spacing: 8) {
                // Level indicator
                Text(String(repeating: "•", count: heading.level))
                    .font(.system(size: 10, weight: .medium))
                    .foregroundColor(levelColor)
                    .frame(width: 30, alignment: .leading)

                // Heading text
                Text(heading.text)
                    .font(.system(size: fontSize, weight: fontWeight))
                    .foregroundColor(.primary)
                    .multilineTextAlignment(.leading)
                    .lineLimit(2)

                Spacer()

                // Line number
                Text("L\(heading.lineNumber)")
                    .font(.system(size: 9, weight: .medium))
                    .foregroundColor(.secondary.opacity(0.6))
            }
            .padding(.horizontal, 12)
            .padding(.vertical, 6)
            .background(
                RoundedRectangle(cornerRadius: 6)
                    .fill(isHovered ? Color.accentColor.opacity(0.1) : Color.clear)
            )
            .contentShape(Rectangle())
        }
        .buttonStyle(.plain)
        .onHover { hovering in
            onHover(hovering)
        }
    }

    private var levelColor: Color {
        switch heading.level {
        case 1: return .blue
        case 2: return .purple
        case 3: return .green
        case 4: return .orange
        case 5: return .pink
        case 6: return .gray
        default: return .secondary
        }
    }

    private var fontSize: CGFloat {
        switch heading.level {
        case 1: return 13
        case 2: return 12
        case 3: return 11.5
        case 4: return 11
        default: return 10.5
        }
    }

    private var fontWeight: Font.Weight {
        switch heading.level {
        case 1: return .semibold
        case 2: return .medium
        default: return .regular
        }
    }
}

// MARK: - Preview

#Preview {
    OutlinePanelView(
        headings: [
            HeadingItem(level: 1, text: "Getting Started", lineNumber: 1),
            HeadingItem(level: 2, text: "Installation", lineNumber: 5),
            HeadingItem(level: 3, text: "Using npm", lineNumber: 10),
            HeadingItem(level: 3, text: "Using yarn", lineNumber: 15),
            HeadingItem(level: 2, text: "Configuration", lineNumber: 20),
            HeadingItem(level: 1, text: "Advanced Topics", lineNumber: 30),
        ],
        onHeadingClick: { lineNumber in
            print("Clicked heading at line \(lineNumber)")
        }
    )
    .frame(width: 250, height: 400)
}
