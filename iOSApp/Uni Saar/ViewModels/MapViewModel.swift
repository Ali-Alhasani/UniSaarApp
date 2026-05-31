//
//  MapViewModel.swift
//  Uni Saar
//
//  Created by Ali Alhasani on 12/21/20.
//  Copyright © 2020 Ali Al-Hasani. All rights reserved.
//

import Foundation
import SwiftyJSON
import Observation

@Observable
class MapViewModel: ParentViewModel {
    var coordinatesLastChanged = ""
    var updatedCoordinates: JSON?

    override init(dataClient: any AppDataClient = DataClient()) {
        super.init(dataClient: dataClient)
    }

    func loadGetMapData() async {
        do {
            let coordinates = try await dataClient.getCampusMapCoordinates(cacheLastChanged: coordinatesLastChanged)
            if coordinates.updateTime != "", coordinates.updateTime != coordinatesLastChanged {
                updateCoordinateCache(newCoordinates: coordinates.mapInfo)
            }
        } catch {
            // silently fail — map loads from local cache
        }
    }

    func updateCoordinateCache(newCoordinates: JSON) {
        do {
            try Data.saveJson(data: newCoordinates.rawData(), toFilename: "Campus_Map_Coord")
            updatedCoordinates = newCoordinates
        } catch {
            print(error)
        }
    }
}
