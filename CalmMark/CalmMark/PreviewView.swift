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

        // Add scroll event listener script
        let scrollScript = WKUserScript(
            source: """
            window.addEventListener('scroll', function() {
                const scrollPercentage = window.scrollY / (document.documentElement.scrollHeight - window.innerHeight);
                window.webkit.messageHandlers.scrollHandler.postMessage({
                    percentage: Math.max(0, Math.min(1, scrollPercentage || 0))
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
        // Only reload if content actually changed and webView is not loading
        guard !html.isEmpty else {
            LogManager.shared.log(.debug, "updateNSView: HTML vacío, saltando actualización", context: "WebView")
            return
        }

        LogManager.shared.log(.debug, "updateNSView: Actualizando WebView con HTML (\(html.count) caracteres)", context: "WebView")

        if webView.isLoading {
            LogManager.shared.log(.debug, "WebView está cargando, deteniendo carga anterior", context: "WebView")
            webView.stopLoading()
        }

        webView.loadHTMLString(html, baseURL: nil)

        // Sync scroll from editor
        if scrollSync.isEnabled && scrollSync.lastScrollSource == .editor {
            context.coordinator.syncScroll(to: scrollSync.scrollPercentage)
        }
    }

    func makeCoordinator() -> Coordinator {
        Coordinator()
    }

    class Coordinator: NSObject, WKNavigationDelegate, WKScriptMessageHandler {
        weak var webView: WKWebView?
        private var isSyncing = false

        func userContentController(_ userContentController: WKUserContentController, didReceive message: WKScriptMessage) {
            guard !isSyncing,
                  message.name == "scrollHandler",
                  let body = message.body as? [String: Any],
                  let percentage = body["percentage"] as? Double else {
                return
            }

            ScrollSyncManager.shared.updateScroll(percentage: percentage, source: .preview)
        }

        func syncScroll(to percentage: Double) {
            guard let webView = webView else { return }

            isSyncing = true

            let script = """
            const maxScroll = document.documentElement.scrollHeight - window.innerHeight;
            const targetScroll = \(percentage) * maxScroll;
            window.scrollTo(0, targetScroll);
            """

            webView.evaluateJavaScript(script) { _, error in
                if let error = error {
                    LogManager.shared.log(.error, "Error sincronizando scroll: \(error.localizedDescription)", context: "WebView")
                }

                DispatchQueue.main.asyncAfter(deadline: .now() + 0.1) {
                    self.isSyncing = false
                }
            }
        }

        func webView(_ webView: WKWebView, didFinish navigation: WKNavigation!) {
            LogManager.shared.log(.success, "✅ Preview cargado exitosamente", context: "WebView")

            // Verificar que realmente hay contenido
            webView.evaluateJavaScript("document.body.innerHTML.length") { result, error in
                if let length = result as? Int {
                    LogManager.shared.log(.info, "Contenido HTML en body: \(length) caracteres", context: "WebView")
                }
            }

            // Restore scroll position after reload
            if ScrollSyncManager.shared.isEnabled {
                self.syncScroll(to: ScrollSyncManager.shared.scrollPercentage)
            }
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

