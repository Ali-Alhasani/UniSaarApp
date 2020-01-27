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
    let showLoadingIndicator: Bindable = Bindable(false)
    var onShowError: ((_ alert: SingleButtonAlert) -> Void)?

    init(dataClient: DataClient = DataClient()) {
        self.dataClient = dataClient
    }

    func showError(error: Error?) {
        //presnt the error without handler
        let okAlert = SingleButtonAlert(message: error?.localizedDescription, action: AlertAction(handler: nil))
        onShowError?(okAlert)
    }
}
