//
//  RootViewModel.swift
//  Uni Saar
//
//  Created by Ali Al-Hasani on 12/19/19.
//  Copyright © 2019 Ali Al-Hasani. All rights reserved.
//

import Foundation
//this class to avoid code duplication in every view model
//maybye it will need more testing
class ParentViewModel {
    var dataClient: DataClient
    let showLoadingIndicator: Bindable = Bindable(true)
    var onShowError: ((_ alert: SingleButtonAlert) -> Void)?

    init(dataClient: DataClient = DataClient()) {
        self.dataClient = dataClient
    }

    func showError(error: Error?, tryAgainHandler: (() -> Void)? = nil) {
        //presnt the error without handler
        let okAlert = SingleButtonAlert(message: error?.localizedDescription, action: AlertAction(handler: nil, tryAgainHandler: tryAgainHandler))
        onShowError?(okAlert)
    }

    func showError(error: LLError?) {
        let okAlert = SingleButtonAlert(message: error?.message, action: AlertAction(handler: nil, tryAgainHandler: nil))
        onShowError?(okAlert)
    }
}
