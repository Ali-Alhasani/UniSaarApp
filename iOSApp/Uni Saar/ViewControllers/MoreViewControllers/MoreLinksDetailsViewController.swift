//
//  MoreLinksDetailsViewController.swift
//  Uni Saar
//
//  Created by Ali Al-Hasani on 12/13/19.
//  Copyright © 2019 Ali Al-Hasani. All rights reserved.
//

import UIKit
import WebKit

class MoreLinksDetailsViewController: UIViewController {
    var linkItem: MoreLinksCellViewModel?
    @IBOutlet weak var webView: WKWebView!
    @IBOutlet weak var activityIndicator: UIActivityIndicatorView!
    override func viewDidLoad() {
        super.viewDidLoad()
        setUplayout()
        load()

        // Do any additional setup after loading the view.
    }
    func load() {
        self.activityIndicator.startAnimating()
        if let urlRequest = getItemURL() {
            self.webView.load(urlRequest)
        }
    }
    func setUplayout() {
        webView.scrollView.isScrollEnabled = true
        webView.navigationDelegate = self
        self.title = linkItem?.nameText
    }
    func getItemURL() -> URLRequest? {
        if let url = linkItem?.linkURL {
            return URLRequest(url: url)
        }
        return nil

    }
    @IBAction func openLinkAction(_ sender: Any) {
        guard let url = linkItem?.linkURL else { return }
        UIApplication.shared.open(url)
    }
    /*
     // MARK: - Navigation

     // In a storyboard-based application, you will often want to do a little preparation before navigation
     override func prepare(for segue: UIStoryboardSegue, sender: Any?) {
     // Get the new view controller using segue.destination.
     // Pass the selected object to the new view controller.
     }
     */

}
extension MoreLinksDetailsViewController: WKNavigationDelegate {
    func webView(_ webView: WKWebView, didFinish navigation: WKNavigation!) {
        DispatchQueue.main.async {
            self.activityIndicator.stopAnimating()
        }
    }
}
