//
//  NotificationTimeViewController.swift
//  Uni Saar
//
//  Created by Ali Al-Hasani on 8/6/20.
//  Copyright © 2020 Ali Al-Hasani. All rights reserved.
//

import UIKit
protocol NotificationTimeDelegate: class {
    func selectedTime(time: Date)
}
class NotificationTimeViewController: UIViewController {
    @IBOutlet weak var timerPicker: UIDatePicker!
    var selectedTime: Date?
    weak var delegate: NotificationTimeDelegate?

    override func viewDidLoad() {
        super.viewDidLoad()
        if let selectedTime = selectedTime {
            timerPicker.date = selectedTime
        }
        // Do any additional setup after loading the view.
    }
    override func viewWillDisappear(_ animated: Bool) {
        super.viewWillDisappear(animated)
        delegate?.selectedTime(time: timerPicker.date)
    }
    @IBAction func doneAction(_ sender: Any) {
        dismiss(animated: true, completion: nil)
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
