import SafariServices
import SwiftUI

/// SwiftUI wrapper for `SFSafariViewController`, which has no first-party SwiftUI
/// equivalent. Used for links the in-app web view hands off (e.g. iCal downloads).
struct SafariView: UIViewControllerRepresentable {
    let url: URL

    func makeUIViewController(context: Context) -> SFSafariViewController {
        let configuration = SFSafariViewController.Configuration()
        configuration.barCollapsingEnabled = false
        return SFSafariViewController(url: url, configuration: configuration)
    }

    func updateUIViewController(_ uiViewController: SFSafariViewController, context: Context) {}
}
