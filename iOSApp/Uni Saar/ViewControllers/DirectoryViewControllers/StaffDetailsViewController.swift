//
//  StaffDetailsViewController.swift
//  Uni Saar
//
//  Created by Ali Al-Hasani on 1/10/20.
//  Copyright © 2020 Ali Al-Hasani. All rights reserved.
//

import UIKit
import Combine

class StaffDetailsViewController: UIViewController {
    @IBOutlet weak var staffTitleLabel: UILabel!
    @IBOutlet weak var nameLabel: UILabel!
    @IBOutlet weak var emailTextView: UITextView!
    @IBOutlet weak var addressLabel: UILabel!
    @IBOutlet weak var contactTextView: UITextView!
    @IBOutlet weak var genderLabel: UILabel!
    @IBOutlet weak var imageView: UIImageView!
    @IBOutlet weak var navigateButton: UIButton!
    var staffId: Int?
    var staff = StaffDetailsViewModel()
    private var cancellables = Set<AnyCancellable>()

    override func viewDidLoad() {
        super.viewDidLoad()
        navigateButton.isHidden = true
        bindViewModel()
    }

    func bindViewModel() {
        if staffId != nil {
            showLoadingActivity()
        }

        staff.$staffDetails
            .dropFirst()
            .sink { [weak self] staffInfo in
                guard let self else { return }
                staffTitleLabel.text = staffInfo.titleText
                nameLabel.text = staffInfo.fullName
                if let email = staffInfo.email {
                    emailTextView.text = email
                }
                if staffInfo.address != " - \n\n" {
                    if (staffInfo.staffDetailsModel?.building != "") || staffInfo.staffDetailsModel?.city != "" {
                        navigateButton.isHidden = false
                    }
                }
                addressLabel.text = staffInfo.address
                contactTextView.text = staffInfo.contactText
                genderLabel.text = staffInfo.genderText
                title = staffInfo.fullName
                if let imageURL = staffInfo.imageURL {
                    imageView.af.setImage(withURL: imageURL)
                }
            }
            .store(in: &cancellables)

        staff.$currentAlert
            .dropFirst()
            .compactMap { $0 }
            .receive(on: DispatchQueue.main)
            .sink { [weak self] alert in
                self?.presentSingleButtonDialog(alert: alert)
            }
            .store(in: &cancellables)

        if let staffID = staffId {
            staff.loadGetStaffDetails(staffId: staffID)
        }

        staff.$showLoadingIndicator
            .dropFirst()
            .sink { [weak self] visible in
                guard let self else { return }
                visible ? showLoadingActivity() : hideLoadingActivity()
            }
            .store(in: &cancellables)
    }

    // MARK: - Navigation
    internal struct SegueIdentifiers {
        static let toStaffAddress = "toAddress"
    }

    @IBAction func navigateAction(_ sender: Any) {
        if let tabbar = tabBarController,
           let topViewNavgation = tabbar.viewControllers?[safe: 1] as? UINavigationController,
           let campusView = topViewNavgation.topViewController as? CampusViewController {
            var address: String?
            if let building = staff.staffDetails.staffDetailsModel?.building, building != "" {
                address = building
            } else if let city = staff.staffDetails.staffDetailsModel?.city, city != "" {
                address = city
            }
            if let address = address {
                campusView.staffAddress = address
                tabbar.selectedIndex = 1
                campusView.activateSearchBar()
            }
        }
    }

    override func prepare(for segue: UIStoryboardSegue, sender: Any?) {
        if segue.identifier == SegueIdentifiers.toStaffAddress,
           let destination = segue.destination as? UINavigationController,
           let destinationViewController = destination.topViewController as? CampusViewController {
            destinationViewController.staffAddress = staff.staffDetails.staffDetailsModel?.building ?? staff.staffDetails.staffDetailsModel?.city
        }
    }
}

extension StaffDetailsViewController: SingleButtonDialogPresenter { }
