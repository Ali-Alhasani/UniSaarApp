import Nuke
import NukeUI
import SwiftUI

struct NewsItemRow: View {
    let viewModel: any NewsFeedCellViewModel

    @State private var imageWidth: CGFloat = 0

    var body: some View {
        VStack(alignment: .leading, spacing: 6) {
            Text(viewModel.newsHeader)
                .font(.caption2)
                .foregroundStyle(.secondary) // .primary in the old cell
            Text(viewModel.titleText)
                .font(.headline)
                .foregroundStyle(Color(.uniHeadlineColor))
                .lineLimit(2 ... 3)
            if let url = viewModel.imageURL {
                newsImage(url: url)
            }
            if !viewModel.subTitleText.isEmpty {
                Text(viewModel.subTitleText)
                    .font(.footnote)
                    .lineLimit(3 ... 6)
            }
        }
        .frame(maxWidth: .infinity, alignment: .leading)
        .contentShape(.rect)
    }

    private func newsImage(url: URL) -> some View {
        LazyImage(url: url) { state in
            imageContent(for: state)
                .animation(.easeInOut(duration: 0.25), value: state.image != nil)
        }
        .processors(imageProcessors)
        .frame(maxWidth: .infinity)
        // Concentric with the card's shape, so the inner radius tracks the card's automatically
        .clipShape(ConcentricRectangle(corners: .concentric, isUniform: true))
        .onGeometryChange(for: CGFloat.self) { $0.size.width } action: { imageWidth = $0 }
    }

    @ViewBuilder
    private func imageContent(for state: LazyImageState) -> some View {
        if let image = state.image {
            image
                .resizable()
                .scaledToFit()
        } else if state.error != nil {
            placeholder {
                Image(systemName: "photo")
                    .font(.largeTitle)
                    .foregroundStyle(.secondary)
            }
        } else {
            placeholder { EmptyView() }
        }
    }

    /// Box that reserves space while the image loads or on failure, so the row height
    /// doesn't jump once the real image settles to its own ratio.
    private func placeholder(@ViewBuilder content: () -> some View) -> some View {
        Color(.systemGray5)
            .aspectRatio(5 / 3, contentMode: .fit)
            .overlay(content())
    }

    /// Nuke converts points → pixels via the screen scale and never upscales
    private var imageProcessors: [any ImageProcessing] {
        guard imageWidth > 0 else { return [] }
        return [ImageProcessors.Resize(width: imageWidth)]
    }
}

#Preview {
    List {
        NewsItemRow(viewModel: NewsFeedModel.newsDemoData.newsList[0])
        NewsItemRow(viewModel: NewsFeedModel.newsDemoData.newsList[1])
        NewsItemRow(viewModel: NewsFeedModel.newsDemoData.newsList[2])
    }
    .listStyle(.plain)
}
