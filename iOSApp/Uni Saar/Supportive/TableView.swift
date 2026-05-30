//
//  tableView.swift
//  Uni Saar
//
//  Created by Ali Al-Hasani on 12/7/19.
//  Copyright © 2019 Ali Al-Hasani. All rights reserved.
//

import Foundation
import UIKit
//commonly used Table View configuration functions in the app
extension UITableView {
    public func showingLoadingView() {
        guard let refreshControl = self.refreshControl, !refreshControl.isRefreshing else { return }
        let spinner = UIActivityIndicatorView(style: .large)
        spinner.color = AppStyle.appGlobalTintColor
        spinner.startAnimating()
        spinner.frame = CGRect(x: 0, y: 0, width: bounds.width, height: 44)
        tableFooterView = spinner
        tableFooterView?.isHidden = false
    }

    public func hideLoadingView() {
        tableFooterView = nil
        endRefreshing()
    }
    public func endRefreshing() {
        refreshControl?.endRefreshing()
    }
    public func setUpRefreshControl() -> UIRefreshControl {
        let refreshControl = UIRefreshControl()
        refreshControl.tintColor = AppStyle.appGlobalTintColor
        return refreshControl
    }
    func layoutTableView(tableBackgroundColor: UIColor = AppStyle.tableViewBackgroundColor, withOutSeparator: Bool = true) {
        self.estimatedRowHeight = 300
        self.rowHeight = UITableView.automaticDimension
        self.backgroundColor = tableBackgroundColor
        if withOutSeparator {
            self.separatorStyle = .none
        } else {
            self.tableFooterView = UIView()
        }
    }

    func reloadRowAt() {
        performBatchUpdates(nil)
    }

    func scrollToTop(animated: Bool) {
        setContentOffset(.zero, animated: animated)
    }
}
