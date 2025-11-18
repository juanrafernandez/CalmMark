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
    @ObservedObject var scrollSync = ScrollSyncManager.shared

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

        // Observe scroll events
        NotificationCenter.default.addObserver(
            context.coordinator,
            selector: #selector(Coordinator.scrollViewDidScroll(_:)),
            name: NSScrollView.didLiveScrollNotification,
            object: scrollView
        )

        // Store reference for toolbar access
        DispatchQueue.main.async {
            textViewRef = textView
        }

        // Store scrollView reference in coordinator
        context.coordinator.scrollView = scrollView

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

        // Sync scroll from preview - only if it changed and we're not already syncing
        if scrollSync.isEnabled &&
           scrollSync.lastScrollSource == .preview &&
           !context.coordinator.isSyncing &&
           abs(scrollSync.scrollPercentage - context.coordinator.lastSyncedPercentage) > 0.001 {
            context.coordinator.lastSyncedPercentage = scrollSync.scrollPercentage
            context.coordinator.syncScroll(to: scrollSync.scrollPercentage)
        }
    }

    func makeCoordinator() -> Coordinator {
        Coordinator(self)
    }

    class Coordinator: NSObject, NSTextViewDelegate {
        var parent: MarkdownTextEditor
        weak var scrollView: NSScrollView?
        var isSyncing = false
        var lastSyncedPercentage: Double = 0.0
        private var syncTimer: DispatchWorkItem?

        init(_ parent: MarkdownTextEditor) {
            self.parent = parent
        }

        @objc func scrollViewDidScroll(_ notification: Notification) {
            // Don't report scroll events during programmatic scrolling
            guard !isSyncing,
                  let scrollView = notification.object as? NSScrollView,
                  let documentView = scrollView.documentView else {
                return
            }

            let visibleRect = scrollView.contentView.documentVisibleRect
            let documentHeight = documentView.bounds.height
            let scrollViewHeight = visibleRect.height

            guard documentHeight > scrollViewHeight else { return }

            let scrollPercentage = visibleRect.origin.y / (documentHeight - scrollViewHeight)
            let clampedPercentage = max(0, min(1, scrollPercentage))

            LogManager.shared.log(.debug, "Editor scroll manual detectado: \(clampedPercentage)", context: "Editor")
            ScrollSyncManager.shared.updateScroll(percentage: clampedPercentage, source: .editor)
        }

        func syncScroll(to percentage: Double) {
            guard let scrollView = scrollView,
                  let documentView = scrollView.documentView else {
                return
            }

            // Cancel any pending timer
            syncTimer?.cancel()

            // Mark as syncing to prevent loop
            isSyncing = true
            LogManager.shared.log(.debug, "Editor sync scroll programático a: \(percentage)", context: "Editor")

            let documentHeight = documentView.bounds.height
            let scrollViewHeight = scrollView.contentView.bounds.height

            guard documentHeight > scrollViewHeight else {
                isSyncing = false
                return
            }

            let targetY = percentage * (documentHeight - scrollViewHeight)
            let clampedY = max(0, min(documentHeight - scrollViewHeight, targetY))

            var newOrigin = scrollView.contentView.bounds.origin
            newOrigin.y = clampedY
            scrollView.contentView.setBoundsOrigin(newOrigin)

            // Keep isSyncing = true for longer to avoid detecting our own scroll
            let workItem = DispatchWorkItem { [weak self] in
                self?.isSyncing = false
                LogManager.shared.log(.debug, "Editor sync finalizado", context: "Editor")
            }
            syncTimer = workItem
            DispatchQueue.main.asyncAfter(deadline: .now() + 0.3, execute: workItem)
        }

        func textDidChange(_ notification: Notification) {
            guard let textView = notification.object as? NSTextView else { return }
            parent.text = textView.string

            // Autocompletado Markdown
            handleMarkdownAutocompletion(in: textView)

            // Apply syntax highlighting
            if parent.settings.syntaxHighlighting {
                parent.applySyntaxHighlighting(to: textView)
            }
        }

        // MARK: - Autocompletado de Markdown
        private func handleMarkdownAutocompletion(in textView: NSTextView) {
            let selectedRange = textView.selectedRange()
            guard selectedRange.location > 0 else { return }

            let text = textView.string as NSString
            let checkLength = min(3, selectedRange.location)
            let checkRange = NSRange(location: selectedRange.location - checkLength, length: checkLength)

            guard checkRange.location >= 0,
                  checkRange.location + checkRange.length <= text.length else { return }

            let recentText = text.substring(with: checkRange)

            // Auto-cerrar paréntesis en links
            if recentText.hasSuffix("](") {
                textView.insertText(")", replacementRange: selectedRange)
                textView.setSelectedRange(NSRange(location: selectedRange.location, length: 0))
            }

            // Auto-cerrar comillas en markdown
            else if recentText.hasSuffix("`") && !recentText.hasSuffix("``") {
                textView.insertText("`", replacementRange: selectedRange)
                textView.setSelectedRange(NSRange(location: selectedRange.location, length: 0))
            }

            // Auto-completar bloques de código
            else if recentText.hasSuffix("```") {
                let completion = "\n\n```"
                textView.insertText(completion, replacementRange: selectedRange)
                textView.setSelectedRange(NSRange(location: selectedRange.location + 1, length: 0))
            }

            // Auto-completar items de lista
            else if recentText.hasSuffix("\n") {
                handleListContinuation(in: textView, at: selectedRange.location)
            }
        }

        private func handleListContinuation(in textView: NSTextView, at location: Int) {
            let text = textView.string as NSString
            guard location > 1 else { return }

            // Buscar la línea anterior
            var lineStart = location - 2
            while lineStart > 0 && text.character(at: lineStart) != 0x0A { // \n
                lineStart -= 1
            }
            if text.character(at: lineStart) == 0x0A {
                lineStart += 1
            }

            let previousLineRange = NSRange(location: lineStart, length: location - lineStart - 1)
            guard previousLineRange.length > 0 else { return }

            let previousLine = text.substring(with: previousLineRange)

            // Detectar lista no ordenada (- o *)
            if let match = previousLine.range(of: "^\\s*([-*])\\s+", options: .regularExpression) {
                let bullet = String(previousLine[match])
                textView.insertText(bullet, replacementRange: NSRange(location: location, length: 0))
                return
            }

            // Detectar lista ordenada (1., 2., etc.)
            if let match = previousLine.range(of: "^\\s*(\\d+)\\.\\s+", options: .regularExpression) {
                let numberStr = previousLine[match].trimmingCharacters(in: CharacterSet(charactersIn: ". "))
                if let number = Int(numberStr) {
                    let nextBullet = "\(number + 1). "
                    textView.insertText(nextBullet, replacementRange: NSRange(location: location, length: 0))
                    return
                }
            }

            // Detectar task list (- [ ] o - [x])
            if let match = previousLine.range(of: "^\\s*-\\s+\\[[ x]\\]\\s+", options: .regularExpression) {
                textView.insertText("- [ ] ", replacementRange: NSRange(location: location, length: 0))
                return
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
