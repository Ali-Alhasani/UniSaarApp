import SwiftUI
import WebKit

/// Full-screen reader for a news item or event. Loads the detail page in the
/// native SwiftUI `WebView`
struct NewsReaderView: View {
    let viewModel: any NewsFeedCellViewModel

    @State private var page: WebPage
    @State private var navigationDecider: ExternalLinkNavigationDecider

    @Environment(\.dynamicTypeSize) private var dynamicTypeSize

    init(viewModel: any NewsFeedCellViewModel) {
        self.viewModel = viewModel
        // The decider must be injected at `WebPage` construction
        let decider = ExternalLinkNavigationDecider()
        decider.articleHost = viewModel.newsItemURL?.url?.host()
        _navigationDecider = State(initialValue: decider)
        _page = State(initialValue: WebPage(navigationDecider: decider))
    }

    var body: some View {
        WebView(page)
            // TODO: `WebView` renders edge-to-edge and ignores the safe area.
            .webViewBackForwardNavigationGestures(.enabled)
            .overlay {
                if page.isLoading {
                    ProgressView()
                        .controlSize(.large)
                }
            }
            .frame(maxWidth: .infinity, maxHeight: .infinity)
            .navigationTitle(viewModel.titleText)
            .navigationBarTitleDisplayMode(.inline)
            .sheet(item: $navigationDecider.pendingSafariLink) { link in
                SafariView(url: link.url)
            }
            .task {
                guard let request = viewModel.newsItemURL else { return }
                page.load(request)
            }
            .onChange(of: dynamicTypeSize) {
                // Web content uses its own CSS, so reflow it on Dynamic Type changes.
                page.reload()
            }
    }
}

/// Routes calendar downloads and links that leave the article to an in-app Safari
@MainActor
@Observable
final class ExternalLinkNavigationDecider: WebPage.NavigationDeciding {
    struct SafariLink: Identifiable {
        let id = UUID()
        let url: URL
    }

    @ObservationIgnored var articleHost: String?

    var pendingSafariLink: SafariLink?

    func decidePolicy(
        for action: WebPage.NavigationAction,
        preferences: inout WebPage.NavigationPreferences
    ) async -> WKNavigationActionPolicy {
        guard let url = action.request.url else { return .allow }

        if url.absoluteString.contains("/iCal?") {
            pendingSafariLink = SafariLink(url: url)
            return .cancel
        }

        // A tapped link that leaves the article's host opens in Safari
        if action.navigationType == .linkActivated, let host = url.host(), host != articleHost {
            pendingSafariLink = SafariLink(url: url)
            return .cancel
        }

        return .allow
    }
}

#Preview {
    NavigationStack {
        NewsReaderView(viewModel: NewsFeedModel.newsDemoData.newsList[0])
    }
}
