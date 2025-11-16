//
//  MarkdownFormattingToolbar.swift
//  CalmMark
//
//  Created by Claude on 2025-11-15.
//

import SwiftUI
import AppKit

struct MarkdownFormattingToolbar: View {
    let onFormat: (MarkdownFormat) -> Void

    var body: some View {
        HStack(spacing: 2) {
            // Headers
            Menu {
                ForEach(1...6, id: \.self) { level in
                    Button("Header \(level)") {
                        onFormat(.header(level))
                    }
                }
            } label: {
                Image(systemName: "textformat.size")
                    .font(.system(size: 13))
                    .frame(width: 20, height: 20)
            }
            .menuStyle(.borderlessButton)
            .help("Headers")

            Divider()
                .frame(height: 16)
                .padding(.horizontal, 4)

            // Bold
            Button(action: { onFormat(.bold) }) {
                Image(systemName: "bold")
                    .font(.system(size: 13))
                    .frame(width: 20, height: 20)
            }
            .buttonStyle(.plain)
            .help("Bold (⌘B)")

            // Italic
            Button(action: { onFormat(.italic) }) {
                Image(systemName: "italic")
                    .font(.system(size: 13))
                    .frame(width: 20, height: 20)
            }
            .buttonStyle(.plain)
            .help("Italic (⌘I)")

            // Strikethrough
            Button(action: { onFormat(.strikethrough) }) {
                Image(systemName: "strikethrough")
                    .font(.system(size: 13))
                    .frame(width: 20, height: 20)
            }
            .buttonStyle(.plain)
            .help("Strikethrough")

            // Code
            Button(action: { onFormat(.inlineCode) }) {
                Image(systemName: "chevron.left.forwardslash.chevron.right")
                    .font(.system(size: 13))
                    .frame(width: 20, height: 20)
            }
            .buttonStyle(.plain)
            .help("Inline Code (⌘K)")

            Divider()
                .frame(height: 16)
                .padding(.horizontal, 4)

            // Lists
            Menu {
                Button("Unordered List") {
                    onFormat(.unorderedList)
                }
                Button("Ordered List") {
                    onFormat(.orderedList)
                }
                Button("Task List") {
                    onFormat(.taskList)
                }
            } label: {
                Image(systemName: "list.bullet")
                    .font(.system(size: 13))
                    .frame(width: 20, height: 20)
            }
            .menuStyle(.borderlessButton)
            .help("Lists")

            // Quote
            Button(action: { onFormat(.blockquote) }) {
                Image(systemName: "quote.opening")
                    .font(.system(size: 13))
                    .frame(width: 20, height: 20)
            }
            .buttonStyle(.plain)
            .help("Blockquote")

            Divider()
                .frame(height: 16)
                .padding(.horizontal, 4)

            // Code Block
            Button(action: { onFormat(.codeBlock) }) {
                Image(systemName: "curlybraces")
                    .font(.system(size: 13))
                    .frame(width: 20, height: 20)
            }
            .buttonStyle(.plain)
            .help("Code Block (⌘⇧K)")

            // Link
            Button(action: { onFormat(.link) }) {
                Image(systemName: "link")
                    .font(.system(size: 13))
                    .frame(width: 20, height: 20)
            }
            .buttonStyle(.plain)
            .help("Link (⌘L)")

            // Image
            Button(action: { onFormat(.image) }) {
                Image(systemName: "photo")
                    .font(.system(size: 13))
                    .frame(width: 20, height: 20)
            }
            .buttonStyle(.plain)
            .help("Image")

            Divider()
                .frame(height: 16)
                .padding(.horizontal, 4)

            // Table
            Button(action: { onFormat(.table) }) {
                Image(systemName: "tablecells")
                    .font(.system(size: 13))
                    .frame(width: 20, height: 20)
            }
            .buttonStyle(.plain)
            .help("Table")

            // Horizontal Rule
            Button(action: { onFormat(.horizontalRule) }) {
                Image(systemName: "minus")
                    .font(.system(size: 13))
                    .frame(width: 20, height: 20)
            }
            .buttonStyle(.plain)
            .help("Horizontal Rule")
        }
        .padding(.horizontal, 8)
        .padding(.vertical, 6)
        .background(Color(NSColor.controlBackgroundColor))
    }
}

enum MarkdownFormat {
    case header(Int)
    case bold
    case italic
    case strikethrough
    case inlineCode
    case codeBlock
    case unorderedList
    case orderedList
    case taskList
    case blockquote
    case link
    case image
    case table
    case horizontalRule
}

// Extension to handle text formatting
extension NSTextView {
    func applyMarkdownFormat(_ format: MarkdownFormat) {
        guard let textStorage = self.textStorage else { return }

        let selectedRange = self.selectedRange()
        let selectedText = (self.string as NSString).substring(with: selectedRange)
        let fullText = self.string as NSString

        var replacement = ""
        var newSelectionRange = selectedRange
        var rangeToReplace = selectedRange

        switch format {
        case .header(let level):
            let prefix = String(repeating: "#", count: level) + " "
            replacement = prefix + selectedText
            newSelectionRange = NSRange(location: selectedRange.location + prefix.count, length: selectedText.count)

        case .bold:
            if selectedText.isEmpty {
                replacement = "**texto**"
                newSelectionRange = NSRange(location: selectedRange.location + 2, length: 5)
            } else {
                // Verificar si hay ** ANTES y DESPUÉS de la selección
                let beforeStart = max(0, selectedRange.location - 2)
                let afterEnd = min(fullText.length, selectedRange.location + selectedRange.length + 2)

                let hasBoldBefore = selectedRange.location >= 2 &&
                                   fullText.substring(with: NSRange(location: beforeStart, length: 2)) == "**"
                let hasBoldAfter = (selectedRange.location + selectedRange.length + 2) <= fullText.length &&
                                  fullText.substring(with: NSRange(location: selectedRange.location + selectedRange.length, length: 2)) == "**"

                if hasBoldBefore && hasBoldAfter {
                    // Toggle OFF: Quitar los ** alrededor
                    replacement = selectedText
                    rangeToReplace = NSRange(location: beforeStart, length: selectedRange.length + 4)
                    newSelectionRange = NSRange(location: beforeStart, length: selectedText.count)
                } else {
                    // Toggle ON: Agregar **
                    replacement = "**\(selectedText)**"
                    newSelectionRange = NSRange(location: selectedRange.location + 2, length: selectedText.count)
                }
            }

        case .italic:
            if selectedText.isEmpty {
                replacement = "*texto*"
                newSelectionRange = NSRange(location: selectedRange.location + 1, length: 5)
            } else {
                // Verificar si hay * ANTES y DESPUÉS de la selección (pero no **)
                let beforeStart = max(0, selectedRange.location - 1)
                let afterEnd = min(fullText.length, selectedRange.location + selectedRange.length + 1)

                let charBefore = selectedRange.location >= 1 ?
                                fullText.substring(with: NSRange(location: beforeStart, length: 1)) : ""
                let charAfter = (selectedRange.location + selectedRange.length + 1) <= fullText.length ?
                               fullText.substring(with: NSRange(location: selectedRange.location + selectedRange.length, length: 1)) : ""

                // Verificar que NO sea ** (bold)
                let charBeforeBefore = selectedRange.location >= 2 ?
                                      fullText.substring(with: NSRange(location: selectedRange.location - 2, length: 1)) : ""
                let charAfterAfter = (selectedRange.location + selectedRange.length + 2) <= fullText.length ?
                                    fullText.substring(with: NSRange(location: selectedRange.location + selectedRange.length + 1, length: 1)) : ""

                let hasItalicBefore = charBefore == "*" && charBeforeBefore != "*"
                let hasItalicAfter = charAfter == "*" && charAfterAfter != "*"

                if hasItalicBefore && hasItalicAfter {
                    // Toggle OFF: Quitar los * alrededor
                    replacement = selectedText
                    rangeToReplace = NSRange(location: beforeStart, length: selectedRange.length + 2)
                    newSelectionRange = NSRange(location: beforeStart, length: selectedText.count)
                } else {
                    // Toggle ON: Agregar *
                    replacement = "*\(selectedText)*"
                    newSelectionRange = NSRange(location: selectedRange.location + 1, length: selectedText.count)
                }
            }

        case .strikethrough:
            if selectedText.isEmpty {
                replacement = "~~texto~~"
                newSelectionRange = NSRange(location: selectedRange.location + 2, length: 5)
            } else {
                // Verificar si hay ~~ ANTES y DESPUÉS de la selección
                let beforeStart = max(0, selectedRange.location - 2)

                let hasStrikeBefore = selectedRange.location >= 2 &&
                                     fullText.substring(with: NSRange(location: beforeStart, length: 2)) == "~~"
                let hasStrikeAfter = (selectedRange.location + selectedRange.length + 2) <= fullText.length &&
                                    fullText.substring(with: NSRange(location: selectedRange.location + selectedRange.length, length: 2)) == "~~"

                if hasStrikeBefore && hasStrikeAfter {
                    // Toggle OFF: Quitar los ~~ alrededor
                    replacement = selectedText
                    rangeToReplace = NSRange(location: beforeStart, length: selectedRange.length + 4)
                    newSelectionRange = NSRange(location: beforeStart, length: selectedText.count)
                } else {
                    // Toggle ON: Agregar ~~
                    replacement = "~~\(selectedText)~~"
                    newSelectionRange = NSRange(location: selectedRange.location + 2, length: selectedText.count)
                }
            }

        case .inlineCode:
            if selectedText.isEmpty {
                replacement = "`código`"
                newSelectionRange = NSRange(location: selectedRange.location + 1, length: 6)
            } else {
                // Verificar si hay ` ANTES y DESPUÉS de la selección
                let beforeStart = max(0, selectedRange.location - 1)

                let hasCodeBefore = selectedRange.location >= 1 &&
                                   fullText.substring(with: NSRange(location: beforeStart, length: 1)) == "`"
                let hasCodeAfter = (selectedRange.location + selectedRange.length + 1) <= fullText.length &&
                                  fullText.substring(with: NSRange(location: selectedRange.location + selectedRange.length, length: 1)) == "`"

                if hasCodeBefore && hasCodeAfter {
                    // Toggle OFF: Quitar los ` alrededor
                    replacement = selectedText
                    rangeToReplace = NSRange(location: beforeStart, length: selectedRange.length + 2)
                    newSelectionRange = NSRange(location: beforeStart, length: selectedText.count)
                } else {
                    // Toggle ON: Agregar `
                    replacement = "`\(selectedText)`"
                    newSelectionRange = NSRange(location: selectedRange.location + 1, length: selectedText.count)
                }
            }

        case .codeBlock:
            if selectedText.isEmpty {
                replacement = "```\ncódigo\n```"
                newSelectionRange = NSRange(location: selectedRange.location + 4, length: 6)
            } else {
                replacement = "```\n\(selectedText)\n```"
                newSelectionRange = NSRange(location: selectedRange.location + 4, length: selectedText.count)
            }

        case .unorderedList:
            let lines = selectedText.isEmpty ? ["item"] : selectedText.components(separatedBy: .newlines)
            replacement = lines.map { "- \($0)" }.joined(separator: "\n")
            newSelectionRange = NSRange(location: selectedRange.location, length: replacement.count)

        case .orderedList:
            let lines = selectedText.isEmpty ? ["item"] : selectedText.components(separatedBy: .newlines)
            replacement = lines.enumerated().map { "\($0.offset + 1). \($0.element)" }.joined(separator: "\n")
            newSelectionRange = NSRange(location: selectedRange.location, length: replacement.count)

        case .taskList:
            let lines = selectedText.isEmpty ? ["tarea"] : selectedText.components(separatedBy: .newlines)
            replacement = lines.map { "- [ ] \($0)" }.joined(separator: "\n")
            newSelectionRange = NSRange(location: selectedRange.location, length: replacement.count)

        case .blockquote:
            let lines = selectedText.isEmpty ? ["cita"] : selectedText.components(separatedBy: .newlines)
            replacement = lines.map { "> \($0)" }.joined(separator: "\n")
            newSelectionRange = NSRange(location: selectedRange.location, length: replacement.count)

        case .link:
            if selectedText.isEmpty {
                replacement = "[texto](url)"
                newSelectionRange = NSRange(location: selectedRange.location + 1, length: 5)
            } else {
                replacement = "[\(selectedText)](url)"
                newSelectionRange = NSRange(location: selectedRange.location + selectedText.count + 3, length: 3)
            }

        case .image:
            if selectedText.isEmpty {
                replacement = "![alt](url)"
                newSelectionRange = NSRange(location: selectedRange.location + 2, length: 3)
            } else {
                replacement = "![\(selectedText)](url)"
                newSelectionRange = NSRange(location: selectedRange.location + selectedText.count + 4, length: 3)
            }

        case .table:
            replacement = """
            | Columna 1 | Columna 2 | Columna 3 |
            |-----------|-----------|-----------|
            | Celda 1   | Celda 2   | Celda 3   |
            | Celda 4   | Celda 5   | Celda 6   |
            """
            newSelectionRange = NSRange(location: selectedRange.location, length: replacement.count)

        case .horizontalRule:
            replacement = "\n---\n"
            newSelectionRange = NSRange(location: selectedRange.location + replacement.count, length: 0)
        }

        // Apply the replacement
        textStorage.replaceCharacters(in: rangeToReplace, with: replacement)
        self.setSelectedRange(newSelectionRange)

        // Trigger text change notification to update bindings
        self.didChangeText()
    }
}
