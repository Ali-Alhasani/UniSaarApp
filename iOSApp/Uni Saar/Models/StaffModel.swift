//
//  StaffModel.swift
//  Uni Saar
//
//  Created by Ali Al-Hasani on 12/6/19.
//  Copyright © 2019 Ali Al-Hasani. All rights reserved.
//

import Foundation

struct StaffModel: Codable, Equatable {
    let staffResults: [StaffResultsModel]
    let staffItemCount: Int
    let hasNextPage: Bool
}

extension StaffModel {
    enum CodingKeys: String, CodingKey {
        case staffResults = "results"
        case staffItemCount = "itemCount"
        case hasNextPage
    }

    init(from decoder: Decoder) throws {
        let container = try decoder.container(keyedBy: CodingKeys.self)
        try self.init(
            staffResults: container.value(.staffResults, default: []),
            staffItemCount: container.value(.staffItemCount, default: 0),
            hasNextPage: container.value(.hasNextPage, default: false)
        )
    }

    static let empty = StaffModel(staffResults: [], staffItemCount: 0, hasNextPage: false)
}

struct StaffResultsModel: Codable, Equatable, Hashable {
    let title: String
    let fullName: String
    let staffID: Int
}

extension StaffResultsModel {
    enum CodingKeys: String, CodingKey {
        case title
        case fullName = "name"
        case staffID = "pid"
    }

    init(from decoder: Decoder) throws {
        let container = try decoder.container(keyedBy: CodingKeys.self)
        try self.init(
            title: container.value(.title, default: ""),
            fullName: container.value(.fullName, default: ""),
            staffID: container.value(.staffID, default: 0)
        )
    }
}

struct StaffDetailsModel: Codable, Equatable {
    let email: String?
    let phoneNumber: String?
    let websiteURL: String?
    let gender: String?
    let title: String?
    let firstName: String?
    let lastName: String?
    let office: String?
    let building: String?
    let street: String?
    let postalCode: String?
    let city: String?
    let fax: String?
    let remarks: String?
    let image: String?
    let officeHour: String?
}

extension StaffDetailsModel {
    enum CodingKeys: String, CodingKey {
        case email = "mail"
        case phoneNumber = "phone"
        case websiteURL = "webpage"
        case gender, title
        case firstName = "firstname"
        case lastName = "lastname"
        case office, building, street, postalCode, city, fax
        case remarks = "remark"
        case image = "imageLink"
        case officeHour
    }

    init(from decoder: Decoder) throws {
        let container = try decoder.container(keyedBy: CodingKeys.self)
        try self.init(
            email: container.optionalValue(.email),
            phoneNumber: container.optionalValue(.phoneNumber),
            websiteURL: container.optionalValue(.websiteURL),
            gender: container.optionalValue(.gender),
            title: container.optionalValue(.title),
            firstName: container.optionalValue(.firstName),
            lastName: container.optionalValue(.lastName),
            office: container.optionalValue(.office),
            building: container.optionalValue(.building),
            street: container.optionalValue(.street),
            postalCode: container.optionalValue(.postalCode),
            city: container.optionalValue(.city),
            fax: container.optionalValue(.fax),
            remarks: container.optionalValue(.remarks),
            image: container.optionalValue(.image),
            officeHour: container.optionalValue(.officeHour)
        )
    }
}

extension StaffModel {
    nonisolated(unsafe) static let deomJSON: [String: Any] = ["name": "Ali Baylan", "title": "", "pid": 9091]
    static let staffDemoData = StaffModel(
        staffResults: [
            StaffResultsModel(title: "", fullName: "Ali Baylan", staffID: 9091),
            StaffResultsModel(title: "", fullName: "Galina Baron", staffID: 16776),
            StaffResultsModel(title: "M. Sc", fullName: "Paanteha Kamali-Moghadam", staffID: 14477)
        ],
        staffItemCount: 3,
        hasNextPage: false
    )
}
