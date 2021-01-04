//
//  AboutAppViewController.swift
//  Uni Saar
//
//  Created by Ali Al-Hasani on 12/13/19.
//  Copyright © 2019 Ali Al-Hasani. All rights reserved.
//

import UIKit

class AboutAppViewController: UIViewController {
    @IBOutlet weak var gitHubText: UITextView!
    override func viewDidLoad() {
        super.viewDidLoad()
        setupGitHubLink()
        // Do any additional setup after loading the view.
    }
    /*
     // MARK: - Navigation
     
     // In a storyboard-based application, you will often want to do a little preparation before navigation
     override func prepare(for segue: UIStoryboardSegue, sender: Any?) {
     // Get the new view controller using segue.destination.
     // Pass the selected object to the new view controller.
     }
     */

    func setupGitHubLink() {
        let fullString = NSLocalizedString("GitHubLinkText", comment: "")
        let gitHubLinkRange = (fullString as NSString).range(of: (NSLocalizedString("GitHub", comment: "")))
        let attributedStr = NSMutableAttributedString(string: fullString)
        attributedStr.addAttribute(.link, value: "gitHubLink", range: gitHubLinkRange)
        gitHubText.delegate = self
        gitHubText.attributedText = attributedStr
        gitHubText.textColor = UIColor.label
        gitHubText.font = UIFont.preferredFont(forTextStyle: .body)
        gitHubText.textAlignment = .center
    }
}

extension AboutAppViewController: UITextViewDelegate {
    func textView(_ textView: UITextView, shouldInteractWith URL: URL, in characterRange: NSRange, interaction: UITextItemInteraction) -> Bool {
        if URL.absoluteString == "gitHubLink" {
            openLink()
            return true
        }
        return false
    }

    func openLink() {
        guard let url = URL(string: "https://github.com/Ali-Alhasani/UniSaarApp") else { return }
        UIApplication.shared.open(url)
    }
}
