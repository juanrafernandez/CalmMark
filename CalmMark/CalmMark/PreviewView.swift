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

    func makeNSView(context: Context) -> WKWebView {
        LogManager.shared.log(.info, "Creando WKWebView", context: "WebView")

        let config = WKWebViewConfiguration()

        // Disable hardware acceleration to avoid Metal shader issues
        config.preferences.setValue(false, forKey: "acceleratedDrawingEnabled")
        config.preferences.setValue(false, forKey: "canvasUsesAcceleratedDrawing")
        config.preferences.setValue(false, forKey: "webGLEnabled")

        // Enable JavaScript (still needed for basic functionality)
        config.preferences.javaScriptEnabled = true

        // Set user agent
        config.applicationNameForUserAgent = "CalmMark"

        let webView = WKWebView(frame: .zero, configuration: config)
        webView.navigationDelegate = context.coordinator

        // Disable hardware acceleration at WebView level too
        webView.setValue(false, forKey: "drawsBackground")

        // Don't allow magnification to avoid complex rendering
        webView.allowsMagnification = false

        LogManager.shared.log(.success, "WKWebView creado correctamente (hardware acceleration disabled)", context: "WebView")

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
    }

    func makeCoordinator() -> Coordinator {
        Coordinator()
    }

    class Coordinator: NSObject, WKNavigationDelegate {
        func webView(_ webView: WKWebView, didFinish navigation: WKNavigation!) {
            LogManager.shared.log(.success, "✅ Preview cargado exitosamente", context: "WebView")

            // Verificar que realmente hay contenido
            webView.evaluateJavaScript("document.body.innerHTML.length") { result, error in
                if let length = result as? Int {
                    LogManager.shared.log(.info, "Contenido HTML en body: \(length) caracteres", context: "WebView")
                }
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

