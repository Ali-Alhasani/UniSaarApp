import CoreData
import SwiftUI

/// Category filter for the news feed. Toggles map directly onto the cached
/// `NewsCategoriesCache` rows
struct FilterFeedView: View {
    let viewModel: FilterNewsViewModel
    let onApply: ([Int]) -> Void

    @Environment(\.dismiss) private var dismiss
    @Environment(\.managedObjectContext) private var context
    @FetchRequest(
        sortDescriptors: [NSSortDescriptor(key: #keyPath(NewsCategoriesCache.isSelected), ascending: false)]
    ) private var categories: FetchedResults<NewsCategoriesCache>
    @State private var activeAlert: SingleButtonAlert?

    var body: some View {
        NavigationStack {
            content
                .navigationTitle(String(localized: "FilterFeedTitle"))
                .navigationBarTitleDisplayMode(.inline)
                .toolbar {
                    ToolbarItem(placement: .cancellationAction) {
                        Button(String(localized: "AlertCancelActionTitle")) {
                            context.rollback()
                            dismiss()
                        }
                    }
                    ToolbarItem(placement: .confirmationAction) {
                        Button(String(localized: "FilterDoneButton")) { apply() }
                    }
                }
                .singleButtonAlert($activeAlert)
                .task {
                    viewModel.onAlert = { activeAlert = $0 }
                    viewModel.onRetry = { Task { await viewModel.loadGetFilterList() } }
                    await viewModel.loadGetFilterList()
                }
        }
    }

    @ViewBuilder
    private var content: some View {
        if viewModel.showLoadingIndicator, categories.isEmpty {
            ProgressView()
                .frame(maxWidth: .infinity, maxHeight: .infinity)
        } else {
            List {
                Section {
                    ForEach(categories, id: \.objectID) { category in
                        Toggle(category.name ?? "", isOn: binding(for: category))
                    }
                } footer: {
                    Text(String(localized: "newsFilter"))
                }
            }
            .refreshable {
                viewModel.isFilterdCacheUpdated = false
                await viewModel.loadGetFilterList()
            }
        }
    }

    /// Edits stay in the managed object in memory. handler read them straight back, so we only touch the store once, on Done.
    private func binding(for category: NewsCategoriesCache) -> Binding<Bool> {
        Binding(
            get: { category.isSelected },
            set: { category.isSelected = $0 }
        )
    }

    private func apply() {
        try? context.save()
        let excluded = categories.filter { !$0.isSelected }.map { Int($0.categoryID) }
        onApply(excluded)
        dismiss()
    }
}
