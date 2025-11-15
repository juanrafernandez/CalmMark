//
//  EditorView.swift
//  CalmMark
//
//  Created by Claude on 2025-11-15.
//

import SwiftUI
import AppKit

struct EditorView: View {
    @Binding var text: String
    @ObservedObject var settings: AppSettings

    var body: some View {
        MarkdownTextEditor(
            text: $text,
            settings: settings
        )
        .background(Color(NSColor.textBackgroundColor))
    }
}

struct MarkdownTextEditor: NSViewRepresentable {
    @Binding var text: String
    var settings: AppSettings

    func makeNSView(context: Context) -> NSScrollView {
        let scrollView = NSTextView.scrollableTextView()
        let textView = scrollView.documentView as! NSTextView

        // Configure text view
        textView.delegate = context.coordinator
        textView.isRichText = false
        textView.autoresizingMask = [.width]
        textView.isVerticallyResizable = true
        textView.isHorizontallyResizable = false
        textView.textContainer?.containerSize = NSSize(width: scrollView.contentSize.width, height: .greatestFiniteMagnitude)
        textView.textContainer?.widthTracksTextView = true

        // Font
        textView.font = NSFont.monospacedSystemFont(
            ofSize: CGFloat(settings.editorFontSize),
            weight: .regular
        )

        // Allow undo
        textView.allowsUndo = true

        // Initial text
        textView.string = text

        // Configure scroll view
        scrollView.hasVerticalScroller = true
        scrollView.autohidesScrollers = true

        return scrollView
    }

    func updateNSView(_ scrollView: NSScrollView, context: Context) {
        guard let textView = scrollView.documentView as? NSTextView else { return }

        // Update font size if changed
        if textView.font?.pointSize != CGFloat(settings.editorFontSize) {
            textView.font = NSFont.monospacedSystemFont(
                ofSize: CGFloat(settings.editorFontSize),
                weight: .regular
            )
        }

        // Update text if different (avoid cursor jumps)
        if textView.string != text {
            let selectedRange = textView.selectedRange()
            textView.string = text
            if selectedRange.location <= textView.string.count {
                textView.setSelectedRange(selectedRange)
            }
        }

        // Apply syntax highlighting
        if settings.syntaxHighlighting {
            applySyntaxHighlighting(to: textView)
        }
    }

    func makeCoordinator() -> Coordinator {
        Coordinator(self)
    }

    class Coordinator: NSObject, NSTextViewDelegate {
        var parent: MarkdownTextEditor

        init(_ parent: MarkdownTextEditor) {
            self.parent = parent
        }

        func textDidChange(_ notification: Notification) {
            guard let textView = notification.object as? NSTextView else { return }
            parent.text = textView.string

            // Apply syntax highlighting
            if parent.settings.syntaxHighlighting {
                parent.applySyntaxHighlighting(to: textView)
            }
        }
    }

    func applySyntaxHighlighting(to textView: NSTextView) {
        guard let storage = textView.textStorage else { return }

        let fullRange = NSRange(location: 0, length: storage.length)

        // Reset formatting
        storage.removeAttribute(.foregroundColor, range: fullRange)
        storage.removeAttribute(.font, range: fullRange)

        // Base font
        let baseFont = NSFont.monospacedSystemFont(
            ofSize: CGFloat(settings.editorFontSize),
            weight: .regular
        )
        storage.addAttribute(.font, value: baseFont, range: fullRange)

        // Get system colors
        let textColor = NSColor.labelColor
        storage.addAttribute(.foregroundColor, value: textColor, range: fullRange)

        // Headers (# to ######)
        highlightPattern(
            pattern: "^#{1,6}\\s+.+$",
            in: storage,
            color: NSColor.systemBlue,
            bold: true
        )

        // Bold (**text** or __text__)
        highlightPattern(
            pattern: "(\\*\\*|__).+?(\\*\\*|__)",
            in: storage,
            color: NSColor.labelColor,
            bold: true
        )

        // Italic (*text* or _text_)
        highlightPattern(
            pattern: "(\\*|_).+?(\\*|_)",
            in: storage,
            color: NSColor.labelColor,
            italic: true
        )

        // Code (`code`)
        highlightPattern(
            pattern: "`[^`]+`",
            in: storage,
            color: NSColor.systemPurple,
            bold: false
        )

        // Code blocks (```...```)
        highlightPattern(
            pattern: "```[\\s\\S]*?```",
            in: storage,
            color: NSColor.systemPurple,
            bold: false
        )

        // Links ([text](url))
        highlightPattern(
            pattern: "\\[[^\\]]+\\]\\([^\\)]+\\)",
            in: storage,
            color: NSColor.systemTeal,
            bold: false
        )

        // Lists (- or * or 1.)
        highlightPattern(
            pattern: "^\\s*[-*]\\s+",
            in: storage,
            color: NSColor.systemOrange,
            bold: false
        )

        highlightPattern(
            pattern: "^\\s*\\d+\\.\\s+",
            in: storage,
            color: NSColor.systemOrange,
            bold: false
        )

        // Blockquotes (> text)
        highlightPattern(
            pattern: "^>\\s+.+$",
            in: storage,
            color: NSColor.systemGray,
            italic: true
        )
    }

    func highlightPattern(
        pattern: String,
        in storage: NSTextStorage,
        color: NSColor,
        bold: Bool = false,
        italic: Bool = false
    ) {
        guard let regex = try? NSRegularExpression(pattern: pattern, options: [.anchorsMatchLines]) else {
            return
        }

        let range = NSRange(location: 0, length: storage.length)
        let matches = regex.matches(in: storage.string, options: [], range: range)

        var font = NSFont.monospacedSystemFont(
            ofSize: CGFloat(settings.editorFontSize),
            weight: bold ? .semibold : .regular
        )

        if italic {
            font = NSFontManager.shared.convert(font, toHaveTrait: .italicFontMask)
        }

        for match in matches {
            storage.addAttribute(.foregroundColor, value: color, range: match.range)
            storage.addAttribute(.font, value: font, range: match.range)
        }
    }
}
