//
//  MapViewModel.swift
//  Uni Saar
//
//  Created by Ali Alhasani on 12/21/20.
//  Copyright © 2020 Ali Al-Hasani. All rights reserved.
//

import Foundation
import SwiftyJSON

class MapViewModel: ParentViewModel {
    var coordinatesLastChanged = ""
    @Published var didUpdateCoordinates: JSON = JSON()

    override init(dataClient: DataClient = DataClient()) {
        super.init(dataClient: dataClient)
    }

    func loadGetMapData() {
        showLoadingIndicator = true
        Task { [weak self] in
            guard let self else { return }
            do {
                let coordinates = try await dataClient.getCampusMapCoordinates(cacheLastChanged: coordinatesLastChanged)
                if coordinates.updateTime != "", coordinates.updateTime != coordinatesLastChanged {
                    updateCoordinateCache(newCoordinates: coordinates.mapInfo)
                }
            } catch {
                // silently fail — map loads from local cache
            }
        }
    }

    func updateCoordinateCache(newCoordinates: JSON) {
        do {
            try Data.saveJson(data: newCoordinates.rawData(), toFilename: "Campus_Map_Coord")
            didUpdateCoordinates = newCoordinates
        } catch {
            print(error)
        }
    }
}
