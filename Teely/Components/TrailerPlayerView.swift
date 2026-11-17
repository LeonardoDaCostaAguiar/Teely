import SwiftUI
import WebKit

enum TrailerPlayerDocument {
    static func origin(bundleIdentifier: String? = Bundle.main.bundleIdentifier) -> URL {
        let host = (bundleIdentifier ?? "").lowercased()
        return URL(string: "https://\(host.isEmpty ? "teely.app" : host)") ?? URL(string: "https://teely.app")!
    }

    static func html(embedURL: URL, title: String) -> String {
        """
        <!doctype html>
        <html>
        <head>
        <meta name="viewport" content="width=device-width, initial-scale=1, maximum-scale=1">
        <style>
        html, body { width: 100%; height: 100%; margin: 0; background: #000; overflow: hidden; }
        iframe { position: absolute; top: 0; left: 0; width: 100%; height: 100%; border: 0; }
        </style>
        </head>
        <body>
        <iframe title="\(escaped(title))" src="\(escaped(embedURL.absoluteString))" referrerpolicy="strict-origin-when-cross-origin" allow="accelerometer; autoplay; clipboard-write; encrypted-media; gyroscope; picture-in-picture; web-share" allowfullscreen></iframe>
        </body>
        </html>
        """
    }

    private static func escaped(_ value: String) -> String {
        value
            .replacingOccurrences(of: "&", with: "&amp;")
            .replacingOccurrences(of: "\"", with: "&quot;")
            .replacingOccurrences(of: "<", with: "&lt;")
            .replacingOccurrences(of: ">", with: "&gt;")
    }
}

struct TrailerPlayerView: UIViewRepresentable {
    let trailer: MediaTrailer

    func makeCoordinator() -> Coordinator {
        Coordinator()
    }

    func makeUIView(context: Context) -> WKWebView {
        let configuration = WKWebViewConfiguration()
        configuration.allowsInlineMediaPlayback = true
        configuration.allowsPictureInPictureMediaPlayback = true
        let view = WKWebView(frame: .zero, configuration: configuration)
        view.navigationDelegate = context.coordinator
        view.uiDelegate = context.coordinator
        view.scrollView.isScrollEnabled = false
        view.scrollView.bounces = false
        view.isOpaque = false
        view.backgroundColor = .black
        view.scrollView.backgroundColor = .black
        return view
    }

    func updateUIView(_ webView: WKWebView, context: Context) {
        let origin = TrailerPlayerDocument.origin()
        guard let url = trailer.embedURL(origin: origin), context.coordinator.loadedURL != url else { return }
        context.coordinator.loadedURL = url
        webView.loadHTMLString(TrailerPlayerDocument.html(embedURL: url, title: trailer.name), baseURL: origin)
    }

    final class Coordinator: NSObject, WKNavigationDelegate, WKUIDelegate {
        var loadedURL: URL?

        static func policy(for navigationType: WKNavigationType) -> WKNavigationActionPolicy {
            navigationType == .linkActivated ? .cancel : .allow
        }

        func webView(
            _ webView: WKWebView,
            decidePolicyFor navigationAction: WKNavigationAction,
            decisionHandler: @escaping (WKNavigationActionPolicy) -> Void
        ) {
            decisionHandler(Self.policy(for: navigationAction.navigationType))
        }

        func webView(
            _ webView: WKWebView,
            createWebViewWith configuration: WKWebViewConfiguration,
            for navigationAction: WKNavigationAction,
            windowFeatures: WKWindowFeatures
        ) -> WKWebView? {
            nil
        }
    }
}
