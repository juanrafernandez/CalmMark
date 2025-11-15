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
    @State private var textViewRef: NSTextView?

    var body: some View {
        VStack(spacing: 0) {
            // Formatting toolbar
            MarkdownFormattingToolbar(onFormat: { format in
                applyFormat(format)
            })

            Divider()

            // Editor
            MarkdownTextEditor(
                text: $text,
                settings: settings,
                textViewRef: $textViewRef
            )
            .background(Color(NSColor.textBackgroundColor))
        }
        .onReceive(NotificationCenter.default.publisher(for: .applyFormat)) { notification in
            if let format = notification.object as? MarkdownFormat {
                applyFormat(format)
            }
        }
    }

    private func applyFormat(_ format: MarkdownFormat) {
        if let textView = textViewRef {
            textView.applyMarkdownFormat(format)
        }
    }
}

struct MarkdownTextEditor: NSViewRepresentable {
    @Binding var text: String
    var settings: AppSettings
    @Binding var textViewRef: NSTextView?

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

        // Enable drag and drop
        textView.registerForDraggedTypes([.fileURL])

        // Configure scroll view
        scrollView.hasVerticalScroller = true
        scrollView.autohidesScrollers = true

        // Store reference for toolbar access
        DispatchQueue.main.async {
            textViewRef = textView
        }

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

        // Drag and drop support
        func textView(_ textView: NSTextView,
                     shouldAcceptDraggingInfo draggingInfo: NSDraggingInfo) -> Bool {
            // Check if we have a file URL
            guard let items = draggingInfo.draggingPasteboard.pasteboardItems else {
                return false
            }

            for item in items {
                if let urlString = item.string(forType: .fileURL),
                   let url = URL(string: urlString),
                   url.pathExtension == "md" {
                    return true
                }
            }

            return false
        }

        func textView(_ textView: NSTextView,
                     handleDraggingInfo draggingInfo: NSDraggingInfo) -> Bool {
            guard let items = draggingInfo.draggingPasteboard.pasteboardItems else {
                return false
            }

            for item in items {
                if let urlString = item.string(forType: .fileURL),
                   let url = URL(string: urlString),
                   url.pathExtension == "md" {
                    // Read the file content
                    if let content = try? String(contentsOf: url, encoding: .utf8) {
                        // Post notification to open the file
                        NotificationCenter.default.post(
                            name: .openDroppedFile,
                            object: url
                        )
                        return true
                    }
                }
            }

            return false
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
