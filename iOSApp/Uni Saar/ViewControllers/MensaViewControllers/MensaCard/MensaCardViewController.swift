//
//  ViewController.swift
//  Mensa-Guthaben
//
//  Created by Georg on 11.08.19.
//  Copyright © 2019 Georg Sieber. All rights reserved.
//

import UIKit
import CoreNFC
import SQLite3

class MainViewController: UIViewController, NFCTagReaderSessionDelegate {

    static var APPID: Int    = 0x5F8415
    static var FILEID: UInt8  = 1
    static var DEMO: Bool   = false
    enum Commands: UInt8 {
        case selectApp = 0x5a
        case readValue = 0x6c
        case getFileSettings = 0xf5

    }
    var session: NFCTagReaderSession?

    override func viewDidLoad() {
        super.viewDidLoad()
        DispatchQueue.main.async {
            self.scanCardAction()
        }
    }

    override func viewDidDisappear(_ animated: Bool) {
        dismissNFC()
    }

    @IBOutlet public weak var labelCurrentBalance: UILabel!
    @IBOutlet public weak var labelLastTransaction: UILabel!
    @IBOutlet public weak var labelCardID: UILabel!
    @IBOutlet public weak var labelDate: UILabel!
    @IBOutlet public weak var viewCardBackground: UIView!

    @IBAction public func scanCardAction() {
        guard NFCTagReaderSession.readingAvailable else {
            let alertController = UIAlertController(
                title: NSLocalizedString("NFC Scanning Not Supported", comment: ""),
                message: NSLocalizedString("This device doesn't support NFC tag scanning.", comment: ""),
                preferredStyle: .alert
            )
            alertController.addAction(UIAlertAction(title: "OK", style: .default, handler: nil))
            self.present(alertController, animated: true, completion: nil)
            return
        }

        session = NFCTagReaderSession(pollingOption: .iso14443, delegate: self)
        session?.alertMessage = NSLocalizedString("Please hold your Student/Mensa card near the NFC sensor.", comment: "")
        session?.begin()
    }

    func tagReaderSessionDidBecomeActive(_ session: NFCTagReaderSession) {
    }
    func tagReaderSession(_ session: NFCTagReaderSession, didInvalidateWithError error: Error) {
        print(error.localizedDescription)
    }
    func tagReaderSession(_ session: NFCTagReaderSession, didDetect tags: [NFCTag]) {
        if tags.count != 1 {
            print("MULTIPLE TAGS! ABORT.")
            return
        }

        if let firstTag = tags.first, case let NFCTag.miFare(tag) = firstTag {

            session.connect(to: firstTag) { (error: Error?) in
                if let error = error {
                    print("CONNECTION ERROR : " + error.localizedDescription )
                    return
                }

                _ = self.parseIDNumberResponse(tag: tag)
                let appIdBuff = self.appendAppIDs()

                // 1st command : select app
                self.send(
                    tag: tag,
                    data: Data(_: self.wrap(
                        command: Commands.selectApp.rawValue, // command : select app
                        parameter: [UInt8(appIdBuff[0]), UInt8(appIdBuff[1]), UInt8(appIdBuff[2])] // appId as byte array
                    )),
                    completion: { (_) -> Void in

                        // 2nd command : read value (balance)
                        self.send(
                            tag: tag,
                            data: Data(_: self.wrap(
                                command: Commands.readValue.rawValue, // command : read value
                                parameter: [MainViewController.FILEID] // file id : 1
                            )),
                            completion: { (balanceData) -> Void in

                                // parse balance response
                                _ =  self.parseBalanceResponse(data: balanceData)

                                // 3rd command : read last trans
                                self.send(
                                    tag: tag,
                                    data: Data(_: self.wrap(
                                        command: Commands.getFileSettings.rawValue, // command : get file settings
                                        parameter: [MainViewController.FILEID] // file id : 1
                                    )),
                                    completion: { (transactionData) -> Void in

                                        _ = self.parseTransactionResponse(data: transactionData)

                                        // insert into history
                                        //self.saveBalanceHistory(currentBalanceValue: currentBalanceValue, lastTransaction: lastTransactionValue, cardID: idInt)

                                        // dismiss iOS NFC window
                                        self.dismissNFC()

                                    })
                            })
                    })
            }

        } else {
            print("INVALID CARD")
        }
    }
    func parseIDNumberResponse(tag: NFCMiFareTag) -> Int {
        var idData = tag.identifier
        if idData.count == 7 {
            idData.append(UInt8(0))
        }
        let idInt = idData.withUnsafeBytes {
            $0.load(as: Int.self)
        }

        print("CONNECTED TO CARD")
        print("CARD-TYPE:"+String(tag.mifareFamily.rawValue))
        print("CARD-ID hex:"+idData.hexEncodedString())
        DispatchQueue.main.async {
            self.labelCardID.text = String(idInt)
        }
        return idInt

    }

    func parseBalanceResponse(data: Data) -> Double {
        var trimmedData = data
        trimmedData.removeLast()
        trimmedData.removeLast()
        trimmedData.reverse()
        let currentBalanceRaw = self.byteArrayToInt(
            buf: [UInt8](trimmedData)
        )
        let currentBalanceValue: Double = self.intToEuro(value: currentBalanceRaw)
        DispatchQueue.main.async {
            self.labelCurrentBalance.text = String(format: "%.2f €", currentBalanceValue)
            self.labelDate.text = self.getDateString()
            UIView.animate(withDuration: 1.0, animations: {
                self.viewCardBackground.backgroundColor = self.getColorByEuro(euro: currentBalanceValue)
            })
        }
        return currentBalanceValue
    }

    func parseTransactionResponse(data: Data) -> Double {
        // parse last transaction response
        var lastTransactionValue: Double = 0
        let buf = [UInt8](data)
        if buf.count > 13 {
            let lastTransactionRaw = self.byteArrayToInt(
                buf: [ buf[13], buf[12] ]
            )
            lastTransactionValue = self.intToEuro(value: lastTransactionRaw)
            DispatchQueue.main.async {
                self.labelLastTransaction.text = String(format: "%.2f €", lastTransactionValue)
            }
        }
        return lastTransactionValue
    }

    func appendAppIDs() -> [Int] {
        var appIdBuff: [Int] = []
        appIdBuff.append((MainViewController.APPID & 0xFF0000) >> 16)
        appIdBuff.append((MainViewController.APPID & 0xFF00) >> 8)
        appIdBuff.append(MainViewController.APPID & 0xFF)
        return appIdBuff
    }

    //    func saveBalanceHistory(currentBalanceValue: Double, lastTransaction: Double, cardID: Int) {
    //        self.db.insertRecord(
    //            balance: currentBalanceValue,
    //            lastTransaction: lastTransaction,
    //            date: self.getDateString(),
    //            cardID: String(cardID)
    //        )
    //
    //    }
    // dismiss iOS NFC window
    func dismissNFC() {
        if let session = session {
            session.invalidate()
        }
    }

    func byteArrayToInt(buf: [UInt8]) -> Int {
        var rawValue: Int = 0
        for byte in buf {
            rawValue = rawValue << 8
            rawValue = rawValue | Int(byte)
        }
        return rawValue
    }
    func intToEuro(value: Int) -> Double {
        return (Double(value)/1000).rounded(toPlaces: 2)
    }
    func getColorByEuro(euro: Double) -> UIColor {
        return UIColor.systemGreen.withAlphaComponent(0.5)
    }

    func getDateString() -> String {
        let dateFormatterGet = DateFormatter()
        dateFormatterGet.dateFormat = "dd.MM.yyyy HH:mm"
        return dateFormatterGet.string(from: Date())
    }

    func wrap(command: UInt8, parameter: [UInt8]?) -> [UInt8] {
        var buff: [UInt8] = []
        buff.append(0x90)
        buff.append(command)
        buff.append(0x00)
        buff.append(0x00)
        if let parameters = parameter {
            buff.append(UInt8(parameters.count))
            for par in parameters {
                buff.append(par)
            }
        }
        buff.append(0x00)
        return buff
    }
    func send(tag: NFCMiFareTag, data: Data, completion: @escaping (_ data: Data) -> Void) {
        print("COMMAND TO CARD => "+data.hexEncodedString())
        tag.sendMiFareCommand(commandPacket: data, completionHandler: { (data: Data, error: Error?) in
            if let error = error {
                print("COMMAND ERROR : "+error.localizedDescription)
                return
            }
            print("CARD RESPONSE <= "+data.hexEncodedString())
            completion(data)
        })
    }

    @IBAction func doneAction(_ sender: Any) {
        self.dismiss(animated: true, completion: nil)
    }

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
    // Rounds the double to decimal places value
    func rounded(toPlaces places: Int) -> Double {
        let divisor = pow(10.0, Double(places))
        return (self * divisor).rounded() / divisor
    }
}
