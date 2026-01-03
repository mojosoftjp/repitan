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
        if let htmlURL = findHelpHTML() {
            // Helpフォルダ全体へのアクセスを許可
            let helpDirectory = htmlURL.deletingLastPathComponent()

            // HTMLを読み込み、キャラクター画像をBase64で埋め込む
            if let htmlContent = loadHTMLWithEmbeddedImage(from: htmlURL) {
                webView.loadHTMLString(htmlContent, baseURL: helpDirectory)
            } else {
                webView.loadFileURL(htmlURL, allowingReadAccessTo: helpDirectory)
            }
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

    /// HTMLを読み込み、キャラクター画像をAssets.xcassetsから埋め込む
    private func loadHTMLWithEmbeddedImage(from htmlURL: URL) -> String? {
        guard var htmlContent = try? String(contentsOf: htmlURL, encoding: .utf8) else {
            return nil
        }

        // SplashImage（キャラクター画像）をBase64で埋め込む
        if let image = UIImage(named: "SplashImage"),
           let imageData = image.pngData() {
            let base64String = imageData.base64EncodedString()
            let dataURL = "data:image/png;base64,\(base64String)"
            htmlContent = htmlContent.replacingOccurrences(
                of: "images/repitan_maru.png",
                with: dataURL
            )
        }

        return htmlContent
    }

    private func findHelpHTML() -> URL? {
        // 方法1: Helpフォルダ内を検索
        if let path = Bundle.main.path(forResource: "help", ofType: "html", inDirectory: "Help") {
            return URL(fileURLWithPath: path)
        }

        // 方法2: ルートで検索
        if let path = Bundle.main.path(forResource: "help", ofType: "html") {
            return URL(fileURLWithPath: path)
        }

        // 方法3: URLで検索
        if let url = Bundle.main.url(forResource: "help", withExtension: "html") {
            return url
        }

        // 方法4: Help/help で検索
        if let url = Bundle.main.url(forResource: "Help/help", withExtension: "html") {
            return url
        }

        return nil
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
