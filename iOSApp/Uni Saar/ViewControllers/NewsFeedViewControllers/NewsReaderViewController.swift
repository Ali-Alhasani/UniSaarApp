//
//  NewsReaderViewController.swift
//  Uni Saar
//
//  Created by Ali Al-Hasani on 12/9/19.
//  Copyright © 2019 Ali Al-Hasani. All rights reserved.
//

import UIKit
import WebKit
import Alamofire
import SafariServices
class NewsReaderViewController: UIViewController {
    @IBOutlet weak var webView: WKWebView!
    @IBOutlet weak var activityIndicator: UIActivityIndicatorView!
    var newsItemViewModel: NewsFeedCellViewModel?
    //let documentController = UIDocumentInteractionController()
    override func viewDidLoad() {
        super.viewDidLoad()
        bindViewModel()
        setUplayout()
        // observer to listen for accessibility changing in the phone settings
        NotificationCenter.default.addObserver(self, selector: #selector(contentSizeDidChange(_:)), name: UIContentSizeCategory.didChangeNotification, object: nil)
        // Do any additional setup after loading the view.
    }
    func bindViewModel() {
        DispatchQueue.main.async {
            self.title = self.newsItemViewModel?.titleText
            self.load()
        }
    }
    func load() {
        self.activityIndicator.startAnimating()
        if let urlRequest = getNewsItemURL() {
            self.webView.load(urlRequest)
        }
    }
    func setUplayout() {
        webView.scrollView.isScrollEnabled = true
        webView.navigationDelegate = self
        webView.backgroundColor = .none
        webView.configuration.userContentController.add(self, name: "ics")
    }
    //Todo
    func getNewsItemURL() -> URLRequest? {
        let baseSiteURl = URLRouter.Constants.baseURLPath
        if let newsId = newsItemViewModel?.newsItem.newsID {
            var fullPath = baseSiteURl
            if newsItemViewModel?.isEvent ?? false {
                fullPath += "/events/details?id=\(newsId)"
            } else {
                fullPath += "/news/details?id=\(newsId)"
            }
            if let url = URL(string: fullPath) {
                return URLRequest(url: url)
            }
        }
        return nil
    }
    //respects the user's choice of content size.
    @objc private func contentSizeDidChange(_ notification: Notification) {
        webView.reload()
    }
    /*
     // MARK: - Navigation
     
     // In a storyboard-based application, you will often want to do a little preparation before navigation
     override func prepare(for segue: UIStoryboardSegue, sender: Any?) {
     // Get the new view controller using segue.destination.
     // Pass the selected object to the new view controller.
     }
     */

    let destination: DownloadRequest.DownloadFileDestination = { _, _ in
        var documentsURL = FileManager.default.urls(for: .documentDirectory, in: .userDomainMask)[0]
        // the name of the file here I kept is yourFileName with appended extension
        documentsURL.appendPathComponent("yourFileName."+"ics")
        return (documentsURL, [.removePreviousFile])
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
        DispatchQueue.main.async {
            self.activityIndicator.stopAnimating()
            self.requestReview()
        }
    }

    func webView(_ webView: WKWebView, decidePolicyFor navigationAction: WKNavigationAction, decisionHandler: @escaping ((WKNavigationActionPolicy) -> Void)) {
        if let url = navigationAction.request.url {
            if url.absoluteString.contains("/iCal?") {
               // change the UIBarButton to black color due to bug into add to Calendar view within the background of navigation is not inherit the app color
                UIBarButtonItem.appearance().setTitleTextAttributes([.foregroundColor: UIColor.labelCustomColor], for: UIControl.State.normal)
                let configuration = SFSafariViewController.Configuration()
                //configuration.entersReaderIfAvailable = true
                configuration.barCollapsingEnabled = false
                let safariVC = SFSafariViewController(url: url, configuration: configuration)
                safariVC.delegate = self
                safariVC.preferredBarTintColor = AppStyle.appNavgationMainColor
                safariVC.preferredControlTintColor = .white
                // hide navigation bar and present safari view controller
                self.present(safariVC, animated: true)
            }
        }
        decisionHandler(.allow)
    }
}
// MARK: - SFSafariViewControllerDelegate
extension NewsReaderViewController: SFSafariViewControllerDelegate {
    func safariViewControllerDidFinish(_ controller: SFSafariViewController) {
        // pop safari view controller and display navigation bar again
        // rest BarButtonItem to app tint color
        UIBarButtonItem.appearance().setTitleTextAttributes([.foregroundColor: UIColor.white], for: UIControl.State.normal)
        controller.dismiss(animated: true, completion: nil)
    }
}
