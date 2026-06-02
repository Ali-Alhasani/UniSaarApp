//
//  StaffDetailsViewController.swift
//  Uni Saar
//
//  Created by Ali Al-Hasani on 1/10/20.
//  Copyright © 2020 Ali Al-Hasani. All rights reserved.
//

import UIKit

@MainActor
class StaffDetailsViewController: UIViewController {
    @IBOutlet var staffTitleLabel: UILabel!
    @IBOutlet var nameLabel: UILabel!
    @IBOutlet var emailTextView: UITextView!
    @IBOutlet var addressLabel: UILabel!
    @IBOutlet var contactTextView: UITextView!
    @IBOutlet var genderLabel: UILabel!
    @IBOutlet var imageView: UIImageView!
    @IBOutlet var navigateButton: UIButton!

    var staffId: Int?
    var staff = StaffDetailsViewModel()

    override func viewDidLoad() {
        super.viewDidLoad()
        navigateButton.isHidden = true
        setupInitialDataLoad()
    }

    /// MODERN CONCURRENCY PATTERN: Native reactive UI pipeline
    /// The runtime automatically intercepts any @Observable read here, tracks it,
    /// and triggers updates safely across frame boundaries without recursive closures.
    override func updateProperties() {
        renderUI()
    }

    private func renderUI() {
        let staffInfo = staff.staffDetails

        // 1. Manage Global Overlays
        if staff.showLoadingIndicator { showLoadingActivity() } else { hideLoadingActivity() }

        // 2. Safe Interception of Alert Triggers (Runs outside the mutation cycle)
        if let alert = staff.currentAlert {
            // Defer property mutation slightly to avoid overlapping write contexts
            Task { @MainActor in
                staff.currentAlert = nil
                presentSingleButtonDialog(alert: alert)
            }
        }

        // 3. Update Presentation Strings Safely
        guard staffInfo.staffDetailsModel != nil else { return }

        staffTitleLabel.text = staffInfo.titleText
        nameLabel.text = staffInfo.fullName
        emailTextView.text = staffInfo.email ?? ""
        addressLabel.text = staffInfo.address
        contactTextView.text = staffInfo.contactText
        genderLabel.text = staffInfo.genderText
        title = staffInfo.fullName

        // Configure explicit button state logic flags cleanly
        let hasBuilding = !(staffInfo.staffDetailsModel?.building?.isEmpty ?? true)
        let hasCity = !(staffInfo.staffDetailsModel?.city?.isEmpty ?? true)
        let isAddressValid = staffInfo.address != " - \n\n"
        navigateButton.isHidden = !(isAddressValid && (hasBuilding || hasCity))

        if let imageURL = staffInfo.imageURL {
            imageView.af.setImage(withURL: imageURL)
        }
    }

    private func setupInitialDataLoad() {
        guard let staffID = staffId else { return }
        Task { [weak self] in
            await self?.staff.loadGetStaffDetails(staffId: staffID)
        }
    }

    // MARK: - Actions & Navigation

    enum SegueIdentifiers {
        static let toStaffAddress = "toAddress"
    }

    @IBAction func navigateAction(_ sender: Any) {
        guard let tabbar = tabBarController,
              let topViewNavigation = tabbar.viewControllers?[safe: 1] as? UINavigationController,
              let campusView = topViewNavigation.topViewController as? CampusViewController else { return }

        let model = staff.staffDetails.staffDetailsModel
        let address = (model?.building != "") ? model?.building : model?.city

        if let targetAddress = address, !targetAddress.isEmpty {
            campusView.staffAddress = targetAddress
            tabbar.selectedIndex = 1
            campusView.activateSearchBar()
        }
    }

    override func prepare(for segue: UIStoryboardSegue, sender: Any?) {
        if segue.identifier == SegueIdentifiers.toStaffAddress,
           let destination = segue.destination as? UINavigationController,
           let campusView = destination.topViewController as? CampusViewController {
            let model = staff.staffDetails.staffDetailsModel
            campusView.staffAddress = model?.building ?? model?.city
        }
    }
}

extension StaffDetailsViewController: SingleButtonDialogPresenter {}
