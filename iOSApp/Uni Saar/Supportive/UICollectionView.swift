//
//  UICollectionView.swift
//  Uni Saar
//
//  Created by Ali Al-Hasani on 12/10/19.
//  Copyright © 2019 Ali Al-Hasani. All rights reserved.
//

import Foundation
import UIKit

public extension UICollectionView {
    func showingLoadingView() {
        guard let refreshControl, !refreshControl.isRefreshing else { return }
        let spinner = UIActivityIndicatorView(style: .large)
        spinner.color = AppStyle.appGlobalTintColor
        spinner.startAnimating()
        backgroundView = spinner
    }

    func hideLoadingView() {
        if backgroundView is UIActivityIndicatorView {
            backgroundView = nil
        }
        refreshControl?.endRefreshing()
    }

    func setUpRefreshControl() -> UIRefreshControl {
        let refreshControl = UIRefreshControl()
        refreshControl.tintColor = AppStyle.appGlobalTintColor
        return refreshControl
    }

    internal func layoutCollectionView(collectionBackgroundColor: UIColor = AppStyle.tableViewBackgroundColor) {
        backgroundColor = collectionBackgroundColor
    }
}
