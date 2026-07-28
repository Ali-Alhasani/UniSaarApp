import SwiftUI

struct NewsFeedView: View {
    @State private var newsViewModel = NewsFeedViewModel()
    @State private var filterViewModel = FilterNewsViewModel()
    @State private var showFilter = false
    @State private var activeAlert: SingleButtonAlert?

    var body: some View {
        content
            .navigationTitle(String(localized: "NewsFeedTitle"))
            .navigationBarTitleDisplayMode(.inline)
            .toolbar { toolbarContent }
            .navigationDestination(for: NewsModel.self) { model in
                NewsReaderView(viewModel: NewsFeedCellViewModel(newsItem: model))
            }
            .sheet(isPresented: $showFilter) {
                FilterFeedView(viewModel: filterViewModel) { excluded in
                    Task { await newsViewModel.loadFirstPage(filterCatgroies: excluded) }
                }
                .environment(\.managedObjectContext, CoreDataStack.sharedInstance.persistentContainer.viewContext)
            }
            .singleButtonAlert($activeAlert)
            .task {
                newsViewModel.onAlert = { activeAlert = $0 }
                newsViewModel.onRetry = { Task { await newsViewModel.loadFirstPage() } }
                await newsViewModel.loadFirstPage()
            }
    }

    @ToolbarContentBuilder
    private var toolbarContent: some ToolbarContent {
        ToolbarItem(placement: .topBarLeading) {
            NavigationLink {
                EventCalendarView()
            } label: {
                Image(systemName: "calendar")
            }
        }
        ToolbarItem(placement: .topBarTrailing) {
            Button {
                filterViewModel.isFilterdCacheUpdated = newsViewModel.isFilterdCacheUpdated
                showFilter = true
            } label: {
                Image(systemName: "line.3.horizontal.decrease.circle")
            }
        }
    }

    @ViewBuilder
    private var content: some View {
        if newsViewModel.showLoadingIndicator, newsViewModel.newsCells.isEmpty {
            ProgressView()
                .frame(maxWidth: .infinity, maxHeight: .infinity)
        } else {
            ScrollView {
                LazyVStack(spacing: 12) {
                    ForEach(newsViewModel.newsCells) { card in
                        cardType(for: card)
                    }
                    paginationFooter
                }
            }
            .contentMargins(16.0, for: .scrollContent)
            .background(Color(.systemGroupedBackground))
            .refreshable {
                await newsViewModel.loadFirstPage()
            }
        }
    }

    @ViewBuilder
    private func cardType(for cardType: FeedItemState<NewsFeedCellViewModel>) -> some View {
        switch cardType {
        case let .normal(viewModel):
            card(for: viewModel)
        case .empty:
            statusMessage(String(localized: "EmptyNews"))
        case let .error(message):
            statusMessage(message)
        }
    }

    private func card(for viewModel: NewsFeedCellViewModel) -> some View {
        NavigationLink(value: viewModel.newsItem) {
            NewsItemRow(viewModel: viewModel)
        }
        .buttonStyle(.plain)
    }

    private func statusMessage(_ text: String) -> some View {
        Text(text)
            .foregroundStyle(.secondary)
            .frame(maxWidth: .infinity)
            .padding()
    }

    @ViewBuilder
    private var paginationFooter: some View {
        if newsViewModel.isPaginating {
            ProgressView()
                .frame(maxWidth: .infinity)
                .padding()
        } else if hasNewsItems {
            Color.clear
                .frame(height: 1)
                .onAppear {
                    Task { await newsViewModel.loadNextPage(filterCatgroies: []) }
                }
        }
    }

    /// True only when real news cards are present, so error placeholder rows don't trip pagination.
    private var hasNewsItems: Bool {
        newsViewModel.newsCells.contains {
            if case .normal = $0 {
                true
            } else {
                false
            }
        }
    }
}

#Preview {
    NavigationStack {
        NewsFeedView()
    }
}
