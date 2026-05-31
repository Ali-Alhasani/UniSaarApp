//
//  NVActivityIndicator.swift
//  Uni Saar
//
//  Created by Ali Alhasani on 9/28/20.
//  Copyright © 2020 Ali Al-Hasani. All rights reserved.
//

import UIKit

private nonisolated(unsafe) var loadingOverlayKey: UInt8 = 0

extension UIViewController {

    private var loadingOverlay: UIView? {
        get { objc_getAssociatedObject(self, &loadingOverlayKey) as? UIView }
        set { objc_setAssociatedObject(self, &loadingOverlayKey, newValue, .OBJC_ASSOCIATION_RETAIN_NONATOMIC) }
    }

    func showLoadingActivity(message: String? = nil) {
        guard loadingOverlay == nil else { return }

        let blurView = UIVisualEffectView(effect: UIBlurEffect(style: .systemMaterial))
        blurView.translatesAutoresizingMaskIntoConstraints = false
        blurView.layer.cornerRadius = 16
        blurView.clipsToBounds = true

        let spinner = UIActivityIndicatorView(style: .large)
        spinner.translatesAutoresizingMaskIntoConstraints = false
        spinner.startAnimating()

        let stack = UIStackView(arrangedSubviews: [spinner])
        stack.translatesAutoresizingMaskIntoConstraints = false
        stack.axis = .vertical
        stack.alignment = .center
        stack.spacing = 10

        if let text = message, !text.isEmpty {
            let label = UILabel()
            label.text = text
            label.textAlignment = .center
            label.font = .systemFont(ofSize: 14, weight: .medium)
            label.numberOfLines = 0
            stack.addArrangedSubview(label)
        }

        blurView.contentView.addSubview(stack)
        view.addSubview(blurView)

        NSLayoutConstraint.activate([
            blurView.centerXAnchor.constraint(equalTo: view.centerXAnchor),
            blurView.centerYAnchor.constraint(equalTo: view.centerYAnchor),
            stack.topAnchor.constraint(equalTo: blurView.contentView.topAnchor, constant: 28),
            stack.bottomAnchor.constraint(equalTo: blurView.contentView.bottomAnchor, constant: -28),
            stack.leadingAnchor.constraint(equalTo: blurView.contentView.leadingAnchor, constant: 28),
            stack.trailingAnchor.constraint(equalTo: blurView.contentView.trailingAnchor, constant: -28),
        ])

        loadingOverlay = blurView
        blurView.alpha = 0
        UIView.animate(withDuration: 0.2) { blurView.alpha = 1 }
    }

    func hideLoadingActivity() {
        guard let overlay = loadingOverlay else { return }
        UIView.animate(withDuration: 0.2, animations: {
            overlay.alpha = 0
        }, completion: { _ in
            overlay.removeFromSuperview()
            self.loadingOverlay = nil
        })
    }
}
