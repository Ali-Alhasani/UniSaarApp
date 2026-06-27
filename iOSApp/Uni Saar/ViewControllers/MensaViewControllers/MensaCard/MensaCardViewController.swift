//
//  MensaCardViewController.swift
//  Mensa-Guthaben
//
//  Created by Georg on 11.08.19.
//  Copyright © 2019 Georg Sieber. All rights reserved.
//

import CoreNFC
import UIKit

private let kNFCAppID: Int = 0x5F8415

@MainActor
class MainViewController: UIViewController {
    private var session: NFCTagReaderSession?
    private var nfcController: MensaNfcController?

    override func viewDidLoad() {
        super.viewDidLoad()
        scanCardAction()
    }

    override func viewDidDisappear(_ animated: Bool) {
        super.viewDidDisappear(animated)
        session?.invalidate()
    }

    @IBOutlet var labelCurrentBalance: UILabel!
    @IBOutlet var labelLastTransaction: UILabel!
    @IBOutlet var labelCardID: UILabel!
    @IBOutlet var labelDate: UILabel!
    @IBOutlet var viewCardBackground: UIView!

    @IBAction func scanCardAction() {
        guard NFCTagReaderSession.readingAvailable else {
            let alertController = UIAlertController(
                title: String(localized: "NFC Scanning Not Supported"),
                message: String(localized: "This device doesn't support NFC tag scanning."),
                preferredStyle: .alert
            )
            alertController.addAction(UIAlertAction(title: "OK", style: .default, handler: nil))
            present(alertController, animated: true)
            return
        }

        nfcController = MensaNfcController(viewController: self)
        session = NFCTagReaderSession(pollingOption: .iso14443, delegate: nfcController!)
        session?.alertMessage = String(localized: "Please hold your Student/Mensa card near the NFC sensor.")
        session?.begin()
    }

    func displayValues(currentBalance: Double?, lastTransaction: Double?, cardId: String?, date: String?) {
        if let balance = currentBalance {
            labelCurrentBalance.text = String(format: "%.2f €", balance)
            UIView.animate(springDuration: 0.7, bounce: 0.25) {
                self.viewCardBackground.backgroundColor = self.getColorByEuro(euro: balance)
            }
        }
        if let txn = lastTransaction {
            labelLastTransaction.text = String(format: "%.2f €", txn)
        }
        if let id = cardId {
            labelCardID.text = id
        }
        labelDate.text = date ?? Self.dateFormatter.string(from: Date())
    }

    @IBAction func doneAction(_ sender: Any) {
        dismiss(animated: true)
    }

    private func getColorByEuro(euro: Double) -> UIColor {
        UIColor.systemGreen.withAlphaComponent(0.5)
    }

    private static let dateFormatter: DateFormatter = {
        let formatter = DateFormatter()
        formatter.dateFormat = "dd.MM.yyyy HH:mm"
        return formatter
    }()
}

extension Data {
    struct HexEncodingOptions: OptionSet {
        let rawValue: Int
        static let upperCase = HexEncodingOptions(rawValue: 1 << 0)
    }

    func hexEncodedString(options: HexEncodingOptions = []) -> String {
        let format = options.contains(.upperCase) ? "%02hhX" : "%02hhx"
        return map { String(format: format, $0) }.joined()
    }
}

extension Double {
    func rounded(toPlaces places: Int) -> Double {
        let divisor = pow(10.0, Double(places))
        return (self * divisor).rounded() / divisor
    }
}
