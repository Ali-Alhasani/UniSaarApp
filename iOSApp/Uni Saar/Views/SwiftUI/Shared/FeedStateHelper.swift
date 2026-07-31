//
//  FeedStateHelper.swift
//  Uni Saar
//
//  Created by Ali tmp on 7/27/26.
//  Copyright © 2026 Ali Al-Hasani. All rights reserved.
//

import Foundation
import SwiftUI

enum FeedItemState<Model: Hashable>: Hashable {
    case normal(cardViewModel: Model)
    case error(message: String)
    case empty
}

struct FeedItemStateView<Model: Hashable, Content: View>: View {
    let item: FeedItemState<Model>
    @ViewBuilder let content: (Model) -> Content

    var body: some View {
        switch item {
        case let .normal(model):
            content(model)
        case .empty:
            ContentUnavailableView(
                String(localized: "EmptyNews"),
                systemImage: "newspaper"
            )
        case let .error(message):
            ContentUnavailableView(
                message,
                systemImage: "exclamationmark.triangle"
            )
        }
    }
}

extension FeedItemState: Identifiable where Model: Identifiable {
    var id: String {
        switch self {
        case let .normal(model):
            "normal-\(model.id)"
        case let .error(message):
            "error-\(message)"
        case .empty:
            "empty"
        }
    }
}
