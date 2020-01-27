//
//  StaffDetailsViewModel.swift
//  Uni Saar
//
//  Created by Ali Al-Hasani on 1/10/20.
//  Copyright © 2020 Ali Al-Hasani. All rights reserved.
//

import Foundation
class StaffDetailsViewModel: ParentViewModel {
    var staffDetails: Bindable = Bindable(StaffViewModel())
    override init(dataClient: DataClient = DataClient()) {
        super.init(dataClient: dataClient)
    }
    func loadGetStaffDetails(staffId: Int) {
        showLoadingIndicator.value = true
        dataClient.getStaffDetails(staffId: staffId, completion: { [weak self] result in
            self?.showLoadingIndicator.value = false
            switch result {
            case .success(let staff):
                self?.staffDetails.value = StaffViewModel(staff)
            case .failure(let error):
                self?.showLoadingIndicator.value = false
                self?.showError(error: error)
            }
        })
    }

}
class StaffViewModel {
    var staffDetailsModel: StaffDetailsModel?
    var fullName: String {
        return (staffDetailsModel?.firstName ?? "") + " " + (staffDetailsModel?.lastName ?? "")
    }
    var titleText: String {
        return staffDetailsModel?.title ?? ""
    }
    var address: String {
        let firstLine = (staffDetailsModel?.building ?? "") + " - " + (staffDetailsModel?.office ?? "")
        let secondLine = staffDetailsModel?.street ?? "" + ", " + (staffDetailsModel?.postalCode ?? "")
        let thirdLine = staffDetailsModel?.city
        return firstLine + "\n" + secondLine + "\n" + (thirdLine ?? "")
    }
    var contactText: String? {
        var contactString = ""
        if let phoneNumber = staffDetailsModel?.phoneNumber, phoneNumber != "" {
            contactString += "☏   " + phoneNumber + "\n"
        }
        if let faxNumber = staffDetailsModel?.fax, faxNumber != "" {
            contactString +=  "⎙   " + faxNumber + "\n"
        }
        if let websiteURL = staffDetailsModel?.websiteURL, websiteURL != "" {
            contactString += "\n" + websiteURL + "\n"
        }
        if let workingHours = staffDetailsModel?.officeHour, workingHours != "" {
            contactString += "\n" + "Office hours: " + workingHours
        }
        return contactString
    }
    var email: String? {
        if let email = staffDetailsModel?.email, email != "" {
             return "✉︎   " + email
        }
        return ""
    }
    var imageURL: URL? {
        return URL(string: staffDetailsModel?.image ?? "")
    }
    var remarkText: String? {
        return staffDetailsModel?.remarks
    }

    var genderText: String {
        var string = ""
        string += staffDetailsModel?.gender ?? ""
        if let remarkText = staffDetailsModel?.remarks, remarkText != "" {
            string += "\n" + remarkText
        }
        return string
    }
    init(_ staffDetailsModel: StaffDetailsModel) {
        self.staffDetailsModel = staffDetailsModel
    }

    public init() {
    }
}
