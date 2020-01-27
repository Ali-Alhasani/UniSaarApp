//
//  MensaLocationsInfoViewController.swift
//  Uni Saar
//
//  Created by Ali Al-Hasani on 12/10/19.
//  Copyright © 2019 Ali Al-Hasani. All rights reserved.
//

import UIKit

class MensaLocationsInfoViewController: UIViewController {

    @IBOutlet weak var imageView: UIImageView!
    @IBOutlet weak var descriptionLabel: UILabel!
    var mensaLocationTitle: String?
    override func viewDidLoad() {
        super.viewDidLoad()
        DispatchQueue.main.async {
            if let mensaLocationTitle = self.mensaLocationTitle {
                self.title = mensaLocationTitle
            }
            self.loadAPI()
        }
        // Do any additional setup after loading the view.
    }

    func loadAPI() {
        let dataClient = DataClient()
        dataClient.getMensaInfo { [weak self] result in
            switch result {
            case .success(let mensaInfo):
                guard let self = self else {
                    return
                }
                self.descriptionLabel.text = mensaInfo.description
                if let imageURL = URL(string: mensaInfo.imageLink) {
                    self.imageView.af_setImage(withURL: imageURL)
                }
                self.title = mensaInfo.locationName
            case .failure(let error):
                let okAlert = SingleButtonAlert(message: error?.localizedDescription, action: AlertAction(handler: nil))
                self?.presentSingleButtonDialog(alert: okAlert)
            }
        }
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
