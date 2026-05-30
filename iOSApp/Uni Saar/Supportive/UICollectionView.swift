//
//  UICollectionView.swift
//  Uni Saar
//
//  Created by Ali Al-Hasani on 12/10/19.
//  Copyright © 2019 Ali Al-Hasani. All rights reserved.
//

import Foundation
import UIKit

extension UICollectionView {
    public func showingLoadingView() {
        guard let refreshControl, !refreshControl.isRefreshing else { return }
        let spinner = UIActivityIndicatorView(style: .large)
        spinner.color = AppStyle.appGlobalTintColor
        spinner.startAnimating()
        backgroundView = spinner
    }

    public func hideLoadingView() {
        if backgroundView is UIActivityIndicatorView {
            backgroundView = nil
        }
        refreshControl?.endRefreshing()
    }

    public func setUpRefreshControl() -> UIRefreshControl {
        let refreshControl = UIRefreshControl()
        refreshControl.tintColor = AppStyle.appGlobalTintColor
        return refreshControl
    }

    func layoutCollectionView(collectionBackgroundColor: UIColor = AppStyle.tableViewBackgroundColor) {
        backgroundColor = collectionBackgroundColor
    }
}
