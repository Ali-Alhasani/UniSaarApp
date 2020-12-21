//
//  JSONSaveLoad.swift
//  Uni Saar
//
//  Created by Ali Alhasani on 12/21/20.
//  Copyright © 2020 Ali Al-Hasani. All rights reserved.
//

import Foundation
import SwiftyJSON
/**
Extension to save/load a JSON object by filename. (".json" extension is assumed and automatically added.)
 */
extension Data {

    static func dataFromFile(withFilename filename: String) -> Data? {
        let fileManager = FileManager.default
        let urls = fileManager.urls(for: .documentDirectory, in: .userDomainMask)
        if let documentsURL = urls.first {
            var fileURL = documentsURL.appendingPathComponent(filename)
            fileURL = fileURL.appendingPathExtension("json")
            if !fileManager.fileExists(atPath: fileURL.path) {
                self.copyFileFromBundleToDocumentsFolder(sourceFile: "Campus_Map_Coord.json")
            }
            let data = try? Data(contentsOf: fileURL)
            return data
        }
        return nil
    }

    static func copyFileFromBundleToDocumentsFolder(sourceFile: String, destinationFile: String = "") {
        let documentsURL = FileManager.default.urls(for: .documentDirectory, in: .userDomainMask).first

        if let documentsURL = documentsURL {
            let sourceURL = Bundle.main.bundleURL.appendingPathComponent(sourceFile)

            // Use the same filename if destination filename is not specified
            let destURL = documentsURL.appendingPathComponent(!destinationFile.isEmpty ? destinationFile : sourceFile)

            do {
                try FileManager.default.copyItem(at: sourceURL, to: destURL)
                print("\(sourceFile) was copied successfully.")
            } catch let error {
                print(error)
            }
        }
    }

    static func saveJson(data: Data, toFilename filename: String) {
        let fileManager = FileManager.default
        let urls = fileManager.urls(for: .documentDirectory, in: .userDomainMask)
        if let documentsURL = urls.first {
            var fileURL = documentsURL.appendingPathComponent(filename)
            fileURL = fileURL.appendingPathExtension("json")
            try? data.write(to: fileURL, options: .atomicWrite)
        }
    }
}
