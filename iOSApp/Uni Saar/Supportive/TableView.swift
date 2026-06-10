//
//  TableView.swift
//  Uni Saar
//
//  Created by Ali Al-Hasani on 12/7/19.
//  Copyright © 2019 Ali Al-Hasani. All rights reserved.
//

import Foundation
import UIKit

/// commonly used Table View configuration functions in the app
public extension UITableView {
    func showingLoadingView() {
        guard let refreshControl, !refreshControl.isRefreshing else { return }
        let spinner = UIActivityIndicatorView(style: .large)
        spinner.color = AppStyle.appGlobalTintColor
        spinner.startAnimating()
        spinner.frame = CGRect(x: 0, y: 0, width: bounds.width, height: 44)
        tableFooterView = spinner
        tableFooterView?.isHidden = false
    }

    func hideLoadingView() {
        tableFooterView = nil
        endRefreshing()
    }

    func endRefreshing() {
        refreshControl?.endRefreshing()
    }

    func setUpRefreshControl() -> UIRefreshControl {
        let refreshControl = UIRefreshControl()
        refreshControl.tintColor = AppStyle.appGlobalTintColor
        return refreshControl
    }

    internal func layoutTableView(tableBackgroundColor: UIColor = AppStyle.tableViewBackgroundColor, withOutSeparator: Bool = true) {
        estimatedRowHeight = 300
        rowHeight = UITableView.automaticDimension
        backgroundColor = tableBackgroundColor
        if withOutSeparator {
            separatorStyle = .none
        } else {
            tableFooterView = UIView()
        }
    }

    internal func reloadRowAt() {
        performBatchUpdates(nil)
    }

    internal func scrollToTop(animated: Bool) {
        setContentOffset(.zero, animated: animated)
    }
}
