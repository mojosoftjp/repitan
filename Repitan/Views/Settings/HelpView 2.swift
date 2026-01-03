import SwiftUI
import WebKit

/// ヘルプ画面 - HTMLヘルプファイルをWebViewで表示
struct HelpView: View {
    var body: some View {
        HelpWebView()
            .navigationTitle("ヘルプ")
            .navigationBarTitleDisplayMode(.inline)
            .ignoresSafeArea(edges: .bottom)
    }
}

/// WebViewでHTMLを表示
struct HelpWebView: UIViewRepresentable {
    func makeUIView(context: Context) -> WKWebView {
        let webView = WKWebView()
        webView.backgroundColor = UIColor.systemBackground
        webView.isOpaque = false

        // HTMLファイルを読み込み
        if let htmlPath = Bundle.main.path(forResource: "help", ofType: "html", inDirectory: "Help") {
            let htmlURL = URL(fileURLWithPath: htmlPath)
            let helpDirectory = htmlURL.deletingLastPathComponent()
            webView.loadFileURL(htmlURL, allowingReadAccessTo: helpDirectory)
        } else {
            // フォールバック: HTMLが見つからない場合
            let fallbackHTML = """
            <!DOCTYPE html>
            <html>
            <head>
                <meta charset="UTF-8">
                <meta name="viewport" content="width=device-width, initial-scale=1.0">
                <style>
                    body {
                        font-family: -apple-system, sans-serif;
                        padding: 40px 20px;
                        text-align: center;
                        color: #64748B;
                    }
                </style>
            </head>
            <body>
                <h2>ヘルプを読み込めませんでした</h2>
                <p>アプリを再インストールしてください。</p>
            </body>
            </html>
            """
            webView.loadHTMLString(fallbackHTML, baseURL: nil)
        }

        return webView
    }

    func updateUIView(_ uiView: WKWebView, context: Context) {
        // 更新不要
    }
}

// MARK: - Preview

#Preview {
    NavigationStack {
        HelpView()
    }
}
