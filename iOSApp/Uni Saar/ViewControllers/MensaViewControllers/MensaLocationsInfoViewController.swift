//
//  MensaLocationsInfoViewController.swift
//  Uni Saar
//
//  Created by Ali Al-Hasani on 12/10/19.
//  Copyright © 2019 Ali Al-Hasani. All rights reserved.
//

import UIKit

@MainActor
class MensaLocationsInfoViewController: UIViewController {
    @IBOutlet var imageView: UIImageView!
    @IBOutlet var descriptionLabel: UILabel!
    var mensaLocationTitle: String?
    override func viewDidLoad() {
        super.viewDidLoad()
        if let mensaLocationTitle {
            title = mensaLocationTitle
        }
        loadAPI()
    }

    func loadAPI() {
        let dataClient = DataClient()
        let locationKey = AppSessionManager.shared.selectedMensaLocation.locationKey
        Task { [weak self] in
            guard let self else { return }
            do {
                let mensaInfo = try await dataClient.getMensaInfo(locationKey: locationKey)
                descriptionLabel.text = mensaInfo.description
                if let imageURL = URL(string: mensaInfo.imageLink) {
                    imageView.af.setImage(withURL: imageURL)
                }
                title = mensaInfo.locationName
            } catch {
                let okAlert = SingleButtonAlert(message: error.localizedDescription, action: AlertAction(handler: nil, tryAgainHandler: { [weak self] in
                    self?.loadAgain()
                }))
                presentSingleButtonDialog(alert: okAlert)
            }
        }
    }

    func loadAgain() {
        loadAPI()
    }
    /*
     // MARK: - Navigation

     // In a storyboard-based application, you will often want to do a little preparation before navigation
     override func prepare(for segue: UIStoryboardSegue, sender: Any?) {
     // Get the new view controller using segue.destination.
     // Pass the selected object to the new view controller.
     }
     */
}

extension MensaLocationsInfoViewController: SingleButtonDialogPresenter {}
