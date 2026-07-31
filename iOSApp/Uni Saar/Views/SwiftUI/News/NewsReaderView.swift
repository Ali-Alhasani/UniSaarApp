import SwiftUI
import WebKit

struct NewsReaderView: View {
    let viewModel: NewsFeedCellViewModel
    @State private var page = WebPage()
    @Environment(\.dynamicTypeSize) private var dynamicTypeSize
    @Environment(\.pixelLength) var onePixel

    private var displayTitle: String {
        page.title.isEmpty ? viewModel.titleText : page.title
    }

    var body: some View {
        WebView(page)
            .scrollDisabled(true)
            .padding(.top, onePixel)
            .overlay { overlayContent }
            .navigationTitle(displayTitle)
            .navigationBarTitleDisplayMode(.inline)
            .task(id: viewModel.newsItemURL) {
                reload()
            }
            .onChange(of: dynamicTypeSize) {
                // Web content uses its own CSS, so reflow it on Dynamic Type changes.
                page.reload()
            }
    }

    @ViewBuilder
    private var overlayContent: some View {
        if viewModel.newsItemURL == nil {
            ContentUnavailableView(
                "No article link available",
                systemImage: "link.badge.plus"
            )
        } else if page.isLoading {
            ProgressView(value: page.estimatedProgress)
                .progressViewStyle(.circular)
        }
    }

    private func reload() {
        guard let url = viewModel.newsItemURL else { return }
        page.load(url)
    }
}

#Preview {
    NavigationStack {
        NewsReaderView(viewModel: NewsFeedCellViewModel(newsItem: NewsFeedModel.newsDemoData.newsList[0]))
    }
}
