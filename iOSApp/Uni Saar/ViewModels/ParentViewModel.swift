//
//  RootViewModel.swift
//  Uni Saar
//
//  Created by Ali Al-Hasani on 12/19/19.
//  Copyright © 2019 Ali Al-Hasani. All rights reserved.
//

import Foundation
import Observation

@MainActor
@Observable
class ParentViewModel {
    @ObservationIgnored var dataClient: any AppDataClient
    var showLoadingIndicator: Bool = false
    var currentAlert: SingleButtonAlert?

    init(dataClient: any AppDataClient = DataClient()) {
        self.dataClient = dataClient
    }

    func showError(error: Error?, tryAgainHandler: (() -> Void)? = nil) {
        currentAlert = SingleButtonAlert(message: error?.localizedDescription, action: AlertAction(handler: nil, tryAgainHandler: tryAgainHandler))
    }

    func showError(error: LLError?) {
        currentAlert = SingleButtonAlert(message: error?.message, action: AlertAction(handler: nil, tryAgainHandler: nil))
    }
}
