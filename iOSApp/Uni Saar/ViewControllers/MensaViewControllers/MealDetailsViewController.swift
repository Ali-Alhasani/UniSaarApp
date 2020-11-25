//
//  MealDetailsViewController.swift
//  Uni Saar
//
//  Created by Ali Al-Hasani on 12/9/19.
//  Copyright © 2019 Ali Al-Hasani. All rights reserved.
//

import UIKit
import NVActivityIndicatorView

class MealDetailsViewController: UIViewController {

    @IBOutlet weak var mealDispalyNameLabel: UILabel!
    @IBOutlet weak var counterEntranceLabel: UILabel!
    @IBOutlet weak var generalNoticesLabel: UILabel!
    @IBOutlet weak var componentsLabel: UILabel!
    @IBOutlet var priceTagNamesLabel: UILabel!
    @IBOutlet var pricesLabel: UILabel!
    @IBOutlet weak var colorView: UIView!
    var mealItemViewModel: MensaMealCellViewModel?
    var meal = MealDetailsViewModel()
    override func viewDidLoad() {
        super.viewDidLoad()
        // Do any additional setup after loading the view.
        self.title = mealItemViewModel?.counterDisplayName
        bindViewModel()
        colorView.setAsCircle(cornerRadius: colorView.frame.height/2)
        colorView.backgroundColor = mealItemViewModel?.counterColor
    }

    func bindViewModel() {
        if mealItemViewModel != nil {
              self.showLoadingActivity()
        }
        meal.mealDetails.bind { [weak self] meal in
            self?.mealDispalyNameLabel.text = meal.mealName
            self?.counterEntranceLabel.text = meal.mealCounterDescription
            self?.generalNoticesLabel.attributedText = meal.generalNoticesText
            self?.componentsLabel.attributedText = meal.mealComponetsText
            self?.priceTagNamesLabel.text = meal.priceTagNamesText
            self?.pricesLabel.text = meal.priceValuesText
            self?.requestReview()
        }
        meal.onShowError = { [weak self] alert in
            self?.presentSingleButtonDialog(alert: alert)
        }
        if let mealID = mealItemViewModel?.mensaMealsModel.mealID {
            meal.noticesText = mealItemViewModel?.noticesList
            meal.loadGetMealDetails(mealId: mealID)
        }

        meal.showLoadingIndicator.bind {  [weak self] visible in
            if let `self` = self {
                visible ? self.showLoadingActivity() : self.hideLoadingActivity()
            }
        }

        //meal.loadGetMockMenu()
    }

    func requestReview() {
        AppStoreReviewManager.requestReviewIfAppropriate(presentedView: self)
    }

//    func showActivityLoad() {
//        DispatchQueue.main.async {
//            self.startAnimating(CGSize(width: 50, height: 50), message: NSLocalizedString("Removing MDM Profile", comment: ""), type: .ballClipRotateMultiple,
//                                fadeInAnimation: nil)
//        }
//    }
    /*
     // MARK: - Navigation

     // In a storyboard-based application, you will often want to do a little preparation before navigation
     override func prepare(for segue: UIStoryboardSegue, sender: Any?) {
     // Get the new view controller using segue.destination.
     // Pass the selected object to the new view controller.
     }
     */

}
extension MealDetailsViewController: SingleButtonDialogPresenter { }
