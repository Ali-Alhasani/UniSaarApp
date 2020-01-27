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
        DispatchQueue.main.async {
            guard let refreshControl = self.refreshControl, !refreshControl.isRefreshing else {
                return
            }
            let spinner = UIActivityIndicatorView()
            if #available(iOS 13.0, *) {
                spinner.style = .large
            } else {
                spinner.style = .whiteLarge
                // Fallback on earlier versions
            }
            spinner.color = AppStyle.appGlobalTintColor
            spinner.startAnimating()
            spinner.frame = CGRect(x: CGFloat(0), y: CGFloat(0), width: self.bounds.width, height: CGFloat(44))
            self.tableFooterView = spinner
            self.tableFooterView?.isHidden = false
        }
    }
    public func hideLoadingView() {
        DispatchQueue.main.async {
            self.tableFooterView = nil
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
    func layoutTableView(tableBackgroundColor: UIColor = AppStyle.tableViewBackgroundColor, withOutSeparator: Bool = true) {
        self.estimatedRowHeight = 300
        self.rowHeight = UITableView.automaticDimension
        self.tableFooterView = UIView()
        self.backgroundColor = tableBackgroundColor
        if withOutSeparator {
            self.separatorStyle = .none
        }

    }

    func reloadRowAt() {
        DispatchQueue.main.async {
            self.beginUpdates()
            self.endUpdates()
        }
    }

    func scrollToTop(animated: Bool) {
        setContentOffset(.zero, animated: animated)
    }
}
