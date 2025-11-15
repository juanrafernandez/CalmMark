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

        LogManager.shared.log(.debug, "HTML generado (\(newHTML.count) caracteres)", context: "Preview")

        // Force reload if webView is already created
        DispatchQueue.main.async {
            if let webView = webView {
                LogManager.shared.log(.info, "Cargando HTML en WebView", context: "Preview")
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
        config.preferences.setValue(true, forKey: "allowFileAccessFromFileURLs")

        // Enable JavaScript (for potential future enhancements)
        config.preferences.javaScriptEnabled = true

        let webView = WKWebView(frame: .zero, configuration: config)
        webView.navigationDelegate = context.coordinator

        // Configure appearance
        webView.setValue(false, forKey: "drawsBackground")

        // Allow magnification
        webView.allowsMagnification = true

        LogManager.shared.log(.success, "WKWebView creado correctamente", context: "WebView")

        // Store reference
        DispatchQueue.main.async {
            self.webView = webView
            LogManager.shared.log(.info, "Referencia de WebView almacenada", context: "WebView")

            // Intentar cargar HTML inicial si ya existe
            if !html.isEmpty {
                LogManager.shared.log(.info, "Cargando HTML inicial (\(html.count) caracteres)", context: "WebView")
                webView.loadHTMLString(html, baseURL: nil)
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
            LogManager.shared.log(.success, "Preview cargado exitosamente", context: "WebView")
        }

        func webView(_ webView: WKWebView, didFail navigation: WKNavigation!, withError error: Error) {
            LogManager.shared.log(.error, "Error al cargar preview: \(error.localizedDescription)", context: "WebView")
        }

        func webView(_ webView: WKWebView, didFailProvisionalNavigation navigation: WKNavigation!, withError error: Error) {
            LogManager.shared.log(.error, "Error provisional al cargar preview: \(error.localizedDescription)", context: "WebView")
        }

        func webView(_ webView: WKWebView, didStartProvisionalNavigation navigation: WKNavigation!) {
            LogManager.shared.log(.debug, "Iniciando carga de preview", context: "WebView")
        }
    }
}

