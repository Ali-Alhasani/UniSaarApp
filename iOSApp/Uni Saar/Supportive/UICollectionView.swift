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
        DispatchQueue.main.async {
            guard let refreshControl = self.refreshControl, !refreshControl.isRefreshing else {
                return
            }
            self.refreshControl = refreshControl
            self.refreshControl?.beginRefreshing()
        }
    }
    public func hideLoadingView() {
        DispatchQueue.main.async {
            self.endRefreshing()
        }
    }
    public func endRefreshing() {
        refreshControl?.endRefreshing()
    }
    public func setUpRefreshControl() -> UIRefreshControl {
        let refreshControl = UIRefreshControl()
        refreshControl.tintColor =  AppStyle.appGlobalTintColor
        return refreshControl
    }
    func layoutCollectionView(collectionBackgroundColor: UIColor = AppStyle.tableViewBackgroundColor) {
        self.backgroundColor = collectionBackgroundColor
    }
}
extension UIRefreshControl {
    func refreshManually() {
        if let scrollView = superview as? UIScrollView {
            scrollView.setContentOffset(CGPoint(x: 0, y: scrollView.contentOffset.y - frame.height), animated: false)
        }
        beginRefreshing()
        sendActions(for: .valueChanged)
    }
}
