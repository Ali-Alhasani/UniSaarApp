import SwiftUI

struct NewsFeedView: View {
    @State private var newsViewModel = NewsFeedViewModel()
    @State private var filterViewModel = FilterNewsViewModel()
    @State private var showFilter = false
    @State private var activeAlert: SingleButtonAlert?
    @ScaledMetric private var cardPadding: CGFloat = 12

    var body: some View {
        content
            .navigationTitle(String(localized: "NewsFeedTitle"))
            .navigationBarTitleDisplayMode(.inline)
            .toolbar {
                ToolbarItem(placement: .topBarLeading) {
                    // TODO: Enable once `EventCalendarView` is ported; disabled for now
                    Button {} label: {
                        Image(systemName: "calendar")
                    }
                    .disabled(true)
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
            .navigationDestination(for: NewsModel.self) { model in
                NewsReaderView(viewModel: model)
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
                newsViewModel.onRetry = { Task { await newsViewModel.loadFirstPage(filterCatgroies: []) } }
                await newsViewModel.loadFirstPage(filterCatgroies: [])
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
                    ForEach(newsViewModel.newsCells.indices, id: \.self) { index in
                        cell(at: index)
                    }
                    paginationFooter
                }
                .padding(.horizontal, 16)
                .padding(.vertical, 8)
            }
            .background(Color(.systemGroupedBackground))
            .refreshable {
                await newsViewModel.loadFirstPage(filterCatgroies: [])
            }
        }
    }

    @ViewBuilder
    private func cell(at index: Int) -> some View {
        switch newsViewModel.newsCells[index] {
        case let .normal(viewModel):
            card(for: viewModel)
        case .empty:
            statusMessage(String(localized: "EmptyNews"))
        case let .error(message):
            statusMessage(message)
        }
    }

    private func card(for viewModel: any NewsFeedCellViewModel) -> some View {
        // nested content (the image) derives a concentric inner radius from it automatically — no second hardcoded radius.
        let shape = RoundedRectangle(cornerRadius: 16, style: .continuous)
        return NavigationLink(value: viewModel.newsItem) {
            NewsItemRow(viewModel: viewModel)
                .padding(cardPadding)
                .frame(maxWidth: .infinity, alignment: .leading)
                .background(Color(.systemBackground), in: shape)
                .containerShape(shape)
        }
        .contentShape(shape)
        .buttonStyle(CardButtonStyle())
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
            // at the list end: coming on screen pulls the next page.
            Color.clear
                .frame(height: 1)
                .onAppear {
                    Task { await newsViewModel.loadNextPage(filterCatgroies: []) }
                }
        }
    }

    /// True only when real news cards are present, so error placeholder rows don't trip pagination.
    private var hasNewsItems: Bool {
        newsViewModel.newsCells.contains { if case .normal = $0 { true } else { false } }
    }
}

/// row press dims only the card instead of flashing the full-width selection
/// a plain List row would show.
private struct CardButtonStyle: ButtonStyle {
    func makeBody(configuration: Configuration) -> some View {
        configuration.label
            .opacity(configuration.isPressed ? 0.7 : 1)
            .animation(.easeOut(duration: 0.15), value: configuration.isPressed)
    }
}

#Preview {
    NavigationStack {
        NewsFeedView()
    }
}
