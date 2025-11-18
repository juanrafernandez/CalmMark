//
//  PreviewView.swift
//  CalmMark
//
//  Created by Claude on 2025-11-15.
//

import SwiftUI
import WebKit

struct PreviewView: View {
    let markdown: String
    @ObservedObject var settings: AppSettings
    @State private var html: String = ""
    @State private var webView: WKWebView?
    @State private var updateTask: DispatchWorkItem?

    var body: some View {
        WebViewWrapper(html: $html, webView: $webView)
            .onChange(of: markdown) { oldValue, newValue in
                LogManager.shared.log(.debug, "Markdown cambió: \(oldValue.count) -> \(newValue.count) caracteres", context: "Preview")
                debouncedUpdate(newValue)
            }
            .onChange(of: settings.appearanceMode) { _, _ in
                LogManager.shared.log(.info, "Cambió modo de apariencia", context: "Preview")
                updateHTML(markdown)
            }
            .onChange(of: settings.previewFontSize) { _, _ in
                LogManager.shared.log(.info, "Cambió tamaño de fuente", context: "Preview")
                updateHTML(markdown)
            }
            .onChange(of: settings.maxPreviewWidth) { _, _ in
                LogManager.shared.log(.info, "Cambió ancho máximo", context: "Preview")
                updateHTML(markdown)
            }
            .onAppear {
                LogManager.shared.log(.info, "PreviewView apareció con markdown de \(markdown.count) caracteres", context: "Preview")
                updateHTML(markdown)
            }
    }

    // Debounce para evitar actualizaciones muy frecuentes
    private func debouncedUpdate(_ markdown: String) {
        updateTask?.cancel()

        let task = DispatchWorkItem { [markdown] in
            updateHTML(markdown)
        }

        updateTask = task

        // Actualizar después de 150ms de inactividad
        DispatchQueue.main.asyncAfter(deadline: .now() + 0.15, execute: task)
    }

    private func updateHTML(_ markdown: String) {
        LogManager.shared.log(.debug, "Iniciando renderizado de markdown (\(markdown.count) caracteres)", context: "Preview")

        let newHTML = MarkdownRenderer.renderToHTML(markdown, settings: settings)
        html = newHTML

        // Log primeros 200 caracteres del HTML para debug
        let preview = String(newHTML.prefix(200))
        LogManager.shared.log(.debug, "HTML generado (\(newHTML.count) caracteres). Inicio: \(preview)...", context: "Preview")

        // Force reload if webView is already created
        DispatchQueue.main.async {
            if let webView = webView {
                LogManager.shared.log(.info, "Cargando HTML en WebView con loadHTMLString", context: "Preview")
                webView.loadHTMLString(newHTML, baseURL: nil)
            } else {
                LogManager.shared.log(.warning, "WebView aún no está inicializado", context: "Preview")
            }
        }
    }
}

struct WebViewWrapper: NSViewRepresentable {
    @Binding var html: String
    @Binding var webView: WKWebView?
    @ObservedObject var scrollSync = ScrollSyncManager.shared

    func makeNSView(context: Context) -> WKWebView {
        LogManager.shared.log(.info, "Creando WKWebView", context: "WebView")

        let config = WKWebViewConfiguration()

        // CRITICAL: Disable all GPU/Metal rendering to avoid crashes
        config.preferences.setValue(false, forKey: "acceleratedDrawingEnabled")
        config.preferences.setValue(false, forKey: "canvasUsesAcceleratedDrawing")
        config.preferences.setValue(false, forKey: "webGLEnabled")

        // Enable JavaScript (still needed for basic functionality)
        config.preferences.javaScriptEnabled = true

        // Add scroll event listener script - calculates source line from scroll position
        let scrollScript = WKUserScript(
            source: """
            window.addEventListener('scroll', function() {
                const docHeight = document.documentElement.scrollHeight;
                const winHeight = window.innerHeight;
                const maxScroll = Math.max(0, docHeight - winHeight);

                let percentage;
                if (maxScroll === 0 || window.scrollY === 0) {
                    percentage = 0;
                } else if (window.scrollY >= maxScroll) {
                    percentage = 1;
                } else {
                    percentage = window.scrollY / maxScroll;
                }

                // Calculate source line from scroll position using interpolation
                const currentScrollY = window.scrollY;
                const elements = Array.from(document.querySelectorAll('[data-source-line]'));

                let estimatedLine = 1;

                if (elements.length > 0) {
                    // Build scroll map
                    const scrollMap = elements.map(el => ({
                        line: parseInt(el.getAttribute('data-source-line')),
                        offsetTop: el.offsetTop,
                        offsetHeight: el.offsetHeight
                    })).sort((a, b) => a.line - b.line);

                    // Find elements surrounding current scroll position
                    let previous = scrollMap[0];
                    let next = null;

                    for (let i = 0; i < scrollMap.length; i++) {
                        if (scrollMap[i].offsetTop <= currentScrollY) {
                            previous = scrollMap[i];
                        }
                        if (scrollMap[i].offsetTop > currentScrollY && !next) {
                            next = scrollMap[i];
                            break;
                        }
                    }

                    // Interpolate to estimate source line
                    if (next && next.line !== previous.line) {
                        const pixelProgress = (currentScrollY - previous.offsetTop) / (next.offsetTop - previous.offsetTop);
                        const lineDiff = next.line - previous.line;
                        estimatedLine = Math.round(previous.line + (pixelProgress * lineDiff));
                    } else {
                        estimatedLine = previous.line;
                    }
                }

                window.webkit.messageHandlers.scrollHandler.postMessage({
                    percentage: percentage,
                    estimatedLine: estimatedLine
                });
            });
            """,
            injectionTime: .atDocumentEnd,
            forMainFrameOnly: true
        )
        config.userContentController.addUserScript(scrollScript)
        config.userContentController.add(context.coordinator, name: "scrollHandler")

        // Set user agent
        config.applicationNameForUserAgent = "CalmMark"

        // Create webView
        let webView = WKWebView(frame: .zero, configuration: config)
        webView.navigationDelegate = context.coordinator

        // Don't allow magnification
        webView.allowsMagnification = false

        LogManager.shared.log(.success, "WKWebView creado correctamente (GPU disabled)", context: "WebView")

        // Store reference
        DispatchQueue.main.async {
            self.webView = webView
            LogManager.shared.log(.info, "Referencia de WebView almacenada", context: "WebView")

            // Intentar cargar HTML inicial si ya existe
            if !html.isEmpty {
                LogManager.shared.log(.info, "Cargando HTML inicial (\(html.count) caracteres)", context: "WebView")
                webView.loadHTMLString(html, baseURL: nil)
            } else {
                LogManager.shared.log(.debug, "No hay HTML inicial para cargar", context: "WebView")
            }
        }

        // Store webView in coordinator
        context.coordinator.webView = webView

        return webView
    }

    func updateNSView(_ webView: WKWebView, context: Context) {
        // Only reload HTML if it actually changed
        guard !html.isEmpty else {
            LogManager.shared.log(.debug, "updateNSView: HTML vacío, saltando actualización", context: "WebView")
            return
        }

        // Check if HTML content changed
        if context.coordinator.lastLoadedHTML != html {
            LogManager.shared.log(.debug, "updateNSView: HTML cambió, recargando WebView (\(html.count) caracteres)", context: "WebView")

            if webView.isLoading {
                LogManager.shared.log(.debug, "WebView está cargando, deteniendo carga anterior", context: "WebView")
                webView.stopLoading()
            }

            context.coordinator.lastLoadedHTML = html
            context.coordinator.isContentLoaded = false  // Reset until didFinish
            webView.loadHTMLString(html, baseURL: nil)
        }

        // Sync scroll from editor - only if content is fully loaded
        if scrollSync.isEnabled &&
           scrollSync.lastScrollSource == .editor &&
           !context.coordinator.isSyncing &&
           context.coordinator.isContentLoaded &&
           scrollSync.currentLine != context.coordinator.lastSyncedLine {
            context.coordinator.lastSyncedPercentage = scrollSync.scrollPercentage
            context.coordinator.lastSyncedLine = scrollSync.currentLine
            context.coordinator.syncScroll(to: scrollSync.scrollPercentage)
        }
    }

    func makeCoordinator() -> Coordinator {
        Coordinator()
    }

    class Coordinator: NSObject, WKNavigationDelegate, WKScriptMessageHandler {
        weak var webView: WKWebView?
        var isSyncing = false
        var lastSyncedPercentage: Double = 0.0
        var lastSyncedLine: Int = 0
        var lastLoadedHTML: String = ""
        var isContentLoaded = false
        private var syncTimer: DispatchWorkItem?

        func userContentController(_ userContentController: WKUserContentController, didReceive message: WKScriptMessage) {
            // Don't report scroll events during programmatic scrolling
            guard !isSyncing,
                  message.name == "scrollHandler",
                  let body = message.body as? [String: Any],
                  let percentage = body["percentage"] as? Double else {
                return
            }

            var clampedPercentage = max(0, min(1, percentage))

            // Snap to extremes for better precision
            if clampedPercentage < 0.01 {
                clampedPercentage = 0.0
            } else if clampedPercentage > 0.99 {
                clampedPercentage = 1.0
            }

            // Get estimated line from JavaScript interpolation (more accurate than percentage)
            let estimatedLine = body["estimatedLine"] as? Int ?? 1
            let currentManager = ScrollSyncManager.shared

            LogManager.shared.log(.debug, "📍 Preview scroll: línea estimada \(estimatedLine) (\(String(format: "%.1f", clampedPercentage * 100))%)", context: "WebView")
            // For preview scroll, we don't have the line text, so pass empty string
            ScrollSyncManager.shared.updateScroll(percentage: clampedPercentage, line: estimatedLine, total: currentManager.totalLines, lineText: "", source: .preview)
        }

        func syncScroll(to percentage: Double) {
            guard let webView = webView, isContentLoaded else {
                LogManager.shared.log(.debug, "Preview sync ignorado - contenido no cargado", context: "WebView")
                return
            }

            // Cancel any pending timer
            syncTimer?.cancel()

            // Mark as syncing to prevent loop
            isSyncing = true

            // Get the target line number from the scroll manager
            let targetLine = ScrollSyncManager.shared.currentLine

            LogManager.shared.log(.debug, "📍 Preview sync: línea \(targetLine)", context: "WebView")
            scrollToSourceLine(targetLine, in: webView)
        }

        // Scroll to a specific source line using interpolation (VSCode-style)
        func scrollToSourceLine(_ targetLine: Int, in webView: WKWebView) {
            let script = """
            (function() {
                try {
                    const targetLine = \(targetLine);
                    console.log('📍 Scrolling to source line:', targetLine);

                    // Build scroll map from elements with data-source-line
                    const elements = Array.from(document.querySelectorAll('[data-source-line]'));
                    console.log('📍 Found elements with data-source-line:', elements.length);

                    if (elements.length === 0) {
                        console.log('⚠️ No elements with data-source-line found');
                        return { success: false, reason: 'no_elements' };
                    }

                    // Build map of line -> {element, offsetTop}
                    const scrollMap = elements.map(el => ({
                        line: parseInt(el.getAttribute('data-source-line')),
                        element: el,
                        offsetTop: el.offsetTop
                    })).sort((a, b) => a.line - b.line);

                    console.log('📍 Scroll map built, lines:', scrollMap.map(m => m.line).join(', '));

                    // Find elements surrounding target line
                    let previous = scrollMap[0];
                    let next = null;

                    for (let i = 0; i < scrollMap.length; i++) {
                        if (scrollMap[i].line <= targetLine) {
                            previous = scrollMap[i];
                        }
                        if (scrollMap[i].line >= targetLine && !next) {
                            next = scrollMap[i];
                            break;
                        }
                    }

                    console.log('📍 Target line:', targetLine);
                    console.log('📍 Previous:', previous.line, 'at', previous.offsetTop);
                    console.log('📍 Next:', next ? next.line + ' at ' + next.offsetTop : 'none');

                    let scrollTo = previous.offsetTop;

                    // If we have both previous and next, interpolate between them
                    if (next && next.line !== previous.line) {
                        const lineDiff = next.line - previous.line;
                        const lineProgress = (targetLine - previous.line) / lineDiff;
                        const pixelDiff = next.offsetTop - previous.offsetTop;
                        scrollTo = previous.offsetTop + (pixelDiff * lineProgress);
                        console.log('📍 Interpolating: progress=' + lineProgress + ', pixelDiff=' + pixelDiff);
                    }
                    // If target line is after previous element, interpolate within the element
                    else if (targetLine > previous.line) {
                        const elementHeight = previous.element.offsetHeight || 0;
                        const lineProgress = Math.min(1, (targetLine - previous.line) / 10); // Assume ~10 lines per element
                        scrollTo = previous.offsetTop + (elementHeight * lineProgress);
                        console.log('📍 Interpolating within element: progress=' + lineProgress + ', height=' + elementHeight);
                    }

                    const beforeScroll = window.scrollY;
                    window.scrollTo({ top: scrollTo, behavior: 'instant' });
                    const afterScroll = window.scrollY;

                    console.log('✅ Scrolled from', beforeScroll, 'to', afterScroll);
                    return {
                        success: true,
                        targetLine: targetLine,
                        scrollBefore: beforeScroll,
                        scrollAfter: afterScroll,
                        previousLine: previous.line,
                        nextLine: next ? next.line : null
                    };
                } catch(e) {
                    console.error('❌ Error in scrollToSourceLine:', e);
                    return { success: false, error: e.toString() };
                }
            })();
            """

            webView.evaluateJavaScript(script) { [weak self] result, error in
                guard let self = self else { return }

                if let error = error {
                    LogManager.shared.log(.error, "❌ Error en scroll por línea: \(error.localizedDescription)", context: "WebView")
                } else if let resultDict = result as? [String: Any] {
                    if let success = resultDict["success"] as? Bool, success {
                        let targetLine = resultDict["targetLine"] as? Int ?? 0
                        let before = resultDict["scrollBefore"] as? Double ?? 0
                        let after = resultDict["scrollAfter"] as? Double ?? 0
                        let prevLine = resultDict["previousLine"] as? Int ?? 0
                        let nextLine = resultDict["nextLine"] as? Int
                        let nextInfo = nextLine != nil ? " next=\(nextLine!)" : " (last)"
                        LogManager.shared.log(.success, "✅ Scroll a línea \(targetLine): prev=\(prevLine)\(nextInfo), scroll: \(Int(before))→\(Int(after))px", context: "WebView")
                    } else {
                        let reason = resultDict["reason"] as? String ?? "unknown"
                        LogManager.shared.log(.warning, "⚠️ No se pudo hacer scroll: \(reason)", context: "WebView")
                    }
                } else {
                    LogManager.shared.log(.warning, "⚠️ Resultado inesperado del scroll: \(String(describing: result))", context: "WebView")
                }

                // Reset syncing flag after a short delay (just enough to ignore echo from our scrollTo)
                let workItem = DispatchWorkItem { [weak self] in
                    self?.isSyncing = false
                }
                self.syncTimer = workItem
                DispatchQueue.main.asyncAfter(deadline: .now() + 0.05, execute: workItem)
            }
        }

        func webView(_ webView: WKWebView, didFinish navigation: WKNavigation!) {
            LogManager.shared.log(.success, "✅ Preview cargado exitosamente", context: "WebView")

            // Mark content as loaded - now safe to execute JavaScript
            isContentLoaded = true

            // Verificar que realmente hay contenido
            webView.evaluateJavaScript("document.body.innerHTML.length") { result, error in
                if let length = result as? Int {
                    LogManager.shared.log(.info, "Contenido HTML en body: \(length) caracteres", context: "WebView")
                }
            }

            // Don't force scroll restoration - let natural sync handle it
            // This prevents the "bounce back" issue when user is manually scrolling
        }

        func webView(_ webView: WKWebView, didFail navigation: WKNavigation!, withError error: Error) {
            LogManager.shared.log(.error, "❌ Error al cargar preview: \(error.localizedDescription)", context: "WebView")
        }

        func webView(_ webView: WKWebView, didFailProvisionalNavigation navigation: WKNavigation!, withError error: Error) {
            LogManager.shared.log(.error, "❌ Error provisional al cargar preview: \(error.localizedDescription)", context: "WebView")
        }

        func webView(_ webView: WKWebView, didStartProvisionalNavigation navigation: WKNavigation!) {
            LogManager.shared.log(.debug, "🔄 Iniciando carga provisional de preview", context: "WebView")
        }

        func webView(_ webView: WKWebView, didCommit navigation: WKNavigation!) {
            LogManager.shared.log(.debug, "📄 WebView committed navigation", context: "WebView")
        }

        func webViewWebContentProcessDidTerminate(_ webView: WKWebView) {
            LogManager.shared.log(.error, "💥 WebView process terminado inesperadamente", context: "WebView")
        }
    }
}

