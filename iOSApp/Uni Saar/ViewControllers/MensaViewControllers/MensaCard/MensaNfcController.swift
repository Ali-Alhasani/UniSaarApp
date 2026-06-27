//
//  MensaNfcController.swift
//  Uni Saar
//

import CoreNFC
import Foundation

final class MensaNfcController: NSObject, NFCTagReaderSessionDelegate {
    private static let appID: Int = 0x5F8415
    private static let fileID: UInt8 = 1

    private weak var viewController: MainViewController?

    init(viewController: MainViewController) {
        self.viewController = viewController
    }

    func tagReaderSessionDidBecomeActive(_ session: NFCTagReaderSession) {}

    func tagReaderSession(_ session: NFCTagReaderSession, didInvalidateWithError error: Error) {
        print(error.localizedDescription)
    }

    func tagReaderSession(_ session: NFCTagReaderSession, didDetect tags: [NFCTag]) {
        for tag in tags {
            communicate(session: session, tag: tag)
            return
        }
    }

    private func communicate(session: NFCTagReaderSession, tag: NFCTag) {
        session.connect(to: tag) { [weak self] error in
            guard let self else { return }
            if let error {
                print("CONNECTION ERROR: \(error.localizedDescription)")
                session.invalidate(errorMessage: String(localized: "Connection error:") + " " + error.localizedDescription)
                return
            }

            var idData = Data()
            switch tag {
            case let .miFare(mifareTag):
                print("CARD TYPE: mifare \(mifareTag.mifareFamily.rawValue)")
                idData = mifareTag.identifier
            case let .iso7816(iso7816Tag):
                print("CARD TYPE: iso7816")
                idData = iso7816Tag.identifier
            default:
                print("INVALID CARD TYPE: \(tag)")
                session.invalidate(errorMessage: String(localized: "Invalid card type."))
                return
            }

            let idInt = idDataToInt(idData)
            print("CARD-ID hex: \(idData.hexEncodedString())")

            let viewCtrl = viewController
            Task { @MainActor in
                viewCtrl?.displayValues(currentBalance: nil, lastTransaction: nil, cardId: String(idInt), date: nil)
            }
            readCardData(session: session, tag: tag)
        }
    }

    private func readCardData(session: NFCTagReaderSession, tag: NFCTag) {
        // 1st command: select app
        send(tag: tag, data: compileNfcRequest(command: 0x5A, parameter: Self.appID.toByteArray())) { [weak self] _ in
            guard let self else { return }

            // 2nd command: read value (balance)
            send(tag: tag, data: compileNfcRequest(command: 0x6C, parameter: [Self.fileID])) { [weak self] balanceData in
                guard let self else { return }
                var trimmed = balanceData
                trimmed.removeLast()
                trimmed.removeLast()
                trimmed.reverse()
                let currentBalanceValue = intToEuro(value: [UInt8](trimmed).toInt())

                let viewCtrl = viewController
                Task { @MainActor in
                    viewCtrl?.displayValues(currentBalance: currentBalanceValue, lastTransaction: nil, cardId: nil, date: nil)
                }

                // 3rd command: get file settings (last transaction)
                send(tag: tag, data: compileNfcRequest(command: 0xF5, parameter: [Self.fileID])) { [weak self] transData in
                    let buf = [UInt8](transData)
                    if buf.count > 13 {
                        let lastTransactionValue = self?.intToEuro(value: [buf[13], buf[12]].toInt()) ?? 0
                        let viewCtrl = self?.viewController
                        Task { @MainActor in
                            viewCtrl?.displayValues(currentBalance: nil, lastTransaction: lastTransactionValue, cardId: nil, date: nil)
                        }
                    }
                    session.invalidate()
                }
            }
        }
    }

    private func send(tag: NFCTag, data: Data, completion: @escaping (Data) -> Void) {
        print("COMMAND TO CARD => \(data.hexEncodedString())")
        switch tag {
        case let .miFare(mifareTag):
            mifareTag.sendMiFareCommand(commandPacket: data) { data, error in
                if let error { print("COMMAND ERROR: \(error.localizedDescription)"); return }
                print("CARD RESPONSE <= \(data.hexEncodedString())")
                completion(data)
            }
        case let .iso7816(iso7816Tag):
            guard let apdu = NFCISO7816APDU(data: data) else { return }
            iso7816Tag.sendCommand(apdu: apdu) { data, _, _, error in
                if let error { print("COMMAND ERROR: \(error.localizedDescription)"); return }
                print("CARD RESPONSE <= \(data.hexEncodedString())")
                completion(data)
            }
        default:
            print("UNSUPPORTED TAG TYPE: \(tag)")
        }
    }

    private func compileNfcRequest(command: UInt8, parameter: [UInt8]?) -> Data {
        var buff: [UInt8] = [0x90, command, 0x00, 0x00]
        if let parameter {
            buff.append(UInt8(parameter.count))
            buff.append(contentsOf: parameter)
        }
        buff.append(0x00)
        return Data(buff)
    }

    private func idDataToInt(_ data: Data) -> Int {
        var idData = data
        if idData.count == 7 { idData.append(UInt8(0)) }
        return idData.withUnsafeBytes { $0.load(as: Int.self) }
    }

    private func intToEuro(value: Int) -> Double {
        (Double(value) / 1000).rounded(toPlaces: 2)
    }
}

extension [UInt8] {
    func toInt() -> Int {
        reduce(0) { ($0 << 8) | Int($1) }
    }
}

extension Int {
    func toByteArray() -> [UInt8] {
        [(self & 0xFF0000) >> 16, (self & 0xFF00) >> 8, self & 0xFF].map { UInt8($0) }
    }
}
