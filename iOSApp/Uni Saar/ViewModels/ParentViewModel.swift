//
//  ParentViewModel.swift
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
    @ObservationIgnored var onAlert: (@MainActor (SingleButtonAlert) -> Void)?
    var showLoadingIndicator: Bool = false

    init(dataClient: any AppDataClient = DataClient()) {
        self.dataClient = dataClient
    }

    func showError(error: Error?, tryAgainHandler: (() -> Void)? = nil) {
        onAlert?(SingleButtonAlert(message: error?.localizedDescription, action: AlertAction(handler: nil, tryAgainHandler: tryAgainHandler)))
    }

    func showError(error: LLError?) {
        onAlert?(SingleButtonAlert(message: error?.message, action: AlertAction(handler: nil, tryAgainHandler: nil)))
    }
}
