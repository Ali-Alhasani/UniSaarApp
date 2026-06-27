//
//  NewsReaderViewController.swift
//  Uni Saar
//
//  Created by Ali Al-Hasani on 12/9/19.
//  Copyright © 2019 Ali Al-Hasani. All rights reserved.
//

import SafariServices
import UIKit
import WebKit

@MainActor
class NewsReaderViewController: UIViewController {
    @IBOutlet var webView: WKWebView!
    @IBOutlet var activityIndicator: UIActivityIndicatorView!
    var newsItemViewModel: NewsFeedCellViewModel?

    override func viewDidLoad() {
        super.viewDidLoad()
        title = newsItemViewModel?.titleText
        setUplayout()
        load()
        NotificationCenter.default.addObserver(self, selector: #selector(reloadWebView), name: UIContentSizeCategory.didChangeNotification, object: nil)
    }

    func load() {
        activityIndicator.startAnimating()
        if let urlRequest = newsItemViewModel?.newsItemURL {
            webView.load(urlRequest)
        }
    }

    func setUplayout() {
        webView.scrollView.isScrollEnabled = true
        webView.navigationDelegate = self
        webView.isOpaque = false
        webView.backgroundColor = .clear
        webView.allowsBackForwardNavigationGestures = true
        webView.configuration.userContentController.add(self, name: "ics")
    }

    @objc private func reloadWebView() {
        webView.reload()
    }

    func requestReview() {
        AppStoreReviewManager.requestReviewIfAppropriate(presentedView: self)
    }
}

extension NewsReaderViewController: WKNavigationDelegate, WKScriptMessageHandler {
    func userContentController(_ userContentController: WKUserContentController, didReceive message: WKScriptMessage) {
        print(message)
    }

    func webView(_ webView: WKWebView, didFinish navigation: WKNavigation!) {
        activityIndicator.stopAnimating()
        requestReview()
    }

    func webView(_ webView: WKWebView, decidePolicyFor navigationAction: WKNavigationAction) async -> WKNavigationActionPolicy {
        if let url = navigationAction.request.url, url.absoluteString.contains("/iCal?") {
            let configuration = SFSafariViewController.Configuration()
            configuration.barCollapsingEnabled = false
            let safariVC = SFSafariViewController(url: url, configuration: configuration)
            safariVC.delegate = self
            present(safariVC, animated: true)
        }
        return .allow
    }
}

// MARK: - SFSafariViewControllerDelegate

extension NewsReaderViewController: @preconcurrency SFSafariViewControllerDelegate {
    func safariViewControllerDidFinish(_ controller: SFSafariViewController) {
        controller.dismiss(animated: true)
    }
}
