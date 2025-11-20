//
//  StatusBarView.swift
//  CalmMark
//
//  Status bar showing document statistics
//

import SwiftUI

struct StatusBarView: View {
    let statistics: DocumentStatistics?

    var body: some View {
        HStack(spacing: 16) {
            if let stats = statistics {
                // Word count
                StatusItem(
                    icon: "doc.text",
                    label: "Words",
                    value: "\(stats.wordCount)"
                )

                Divider()
                    .frame(height: 12)

                // Character count
                StatusItem(
                    icon: "textformat.abc",
                    label: "Characters",
                    value: "\(stats.characterCount)"
                )

                Divider()
                    .frame(height: 12)

                // Lines
                StatusItem(
                    icon: "text.alignleft",
                    label: "Lines",
                    value: "\(stats.lineCount)"
                )

                Divider()
                    .frame(height: 12)

                // Reading time
                StatusItem(
                    icon: "clock",
                    label: stats.readingTimeText,
                    value: nil
                )

                Spacer()

                // Additional stats (on hover/popover)
                Button(action: {}) {
                    Image(systemName: "info.circle")
                        .font(.system(size: 11))
                        .foregroundColor(.secondary)
                }
                .buttonStyle(.plain)
                .popover(isPresented: .constant(false)) {
                    DetailedStatsView(statistics: stats)
                }
                .help("More statistics")
            } else {
                Text("No document")
                    .font(.system(size: 11))
                    .foregroundColor(.secondary)

                Spacer()
            }
        }
        .padding(.horizontal, 12)
        .padding(.vertical, 6)
        .background(Color(nsColor: .controlBackgroundColor).opacity(0.95))
        .frame(height: 28)
    }
}

// MARK: - Status Item

private struct StatusItem: View {
    let icon: String
    let label: String
    let value: String?

    var body: some View {
        HStack(spacing: 4) {
            Image(systemName: icon)
                .font(.system(size: 10))
                .foregroundColor(.secondary)

            if let value = value {
                Text(value)
                    .font(.system(size: 11, weight: .medium))
                    .foregroundColor(.primary)

                Text(label)
                    .font(.system(size: 10))
                    .foregroundColor(.secondary)
            } else {
                Text(label)
                    .font(.system(size: 11))
                    .foregroundColor(.secondary)
            }
        }
    }
}

// MARK: - Detailed Stats Popover

private struct DetailedStatsView: View {
    let statistics: DocumentStatistics

    var body: some View {
        VStack(alignment: .leading, spacing: 12) {
            Text("Document Statistics")
                .font(.system(size: 13, weight: .semibold))
                .foregroundColor(.primary)

            Divider()

            // Text stats
            VStack(alignment: .leading, spacing: 6) {
                DetailRow(label: "Words", value: "\(statistics.wordCount)")
                DetailRow(label: "Characters", value: "\(statistics.characterCount)")
                DetailRow(label: "Characters (no spaces)", value: "\(statistics.characterCountNoSpaces)")
                DetailRow(label: "Lines", value: "\(statistics.lineCount)")
                DetailRow(label: "Paragraphs", value: "\(statistics.paragraphCount)")
            }

            Divider()

            // Structure stats
            VStack(alignment: .leading, spacing: 6) {
                DetailRow(label: "Headings", value: "\(statistics.headingCount)")
                DetailRow(label: "Links", value: "\(statistics.linkCount)")
                DetailRow(label: "Images", value: "\(statistics.imageCount)")
                DetailRow(label: "Code blocks", value: "\(statistics.codeBlockCount)")
            }

            Divider()

            // Reading time
            HStack {
                Image(systemName: "clock")
                    .font(.system(size: 11))
                    .foregroundColor(.secondary)

                Text("Reading time:")
                    .font(.system(size: 11))
                    .foregroundColor(.secondary)

                Spacer()

                Text(statistics.readingTimeText)
                    .font(.system(size: 11, weight: .medium))
                    .foregroundColor(.primary)
            }
        }
        .padding(12)
        .frame(width: 220)
    }
}

private struct DetailRow: View {
    let label: String
    let value: String

    var body: some View {
        HStack {
            Text(label)
                .font(.system(size: 11))
                .foregroundColor(.secondary)

            Spacer()

            Text(value)
                .font(.system(size: 11, weight: .medium))
                .foregroundColor(.primary)
                .monospacedDigit()
        }
    }
}

// MARK: - Preview

#Preview("Status Bar") {
    VStack(spacing: 0) {
        Color.gray.opacity(0.2)

        StatusBarView(statistics: DocumentStatistics(
            wordCount: 1234,
            characterCount: 7890,
            characterCountNoSpaces: 6543,
            lineCount: 156,
            paragraphCount: 42,
            headingCount: 8,
            linkCount: 15,
            imageCount: 3,
            codeBlockCount: 5,
            readingTimeMinutes: 5
        ))
    }
    .frame(width: 600, height: 400)
}

#Preview("Detailed Stats") {
    DetailedStatsView(statistics: DocumentStatistics(
        wordCount: 1234,
        characterCount: 7890,
        characterCountNoSpaces: 6543,
        lineCount: 156,
        paragraphCount: 42,
        headingCount: 8,
        linkCount: 15,
        imageCount: 3,
        codeBlockCount: 5,
        readingTimeMinutes: 5
    ))
}
