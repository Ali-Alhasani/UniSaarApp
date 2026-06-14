//
//  MapViewModel.swift
//  Uni Saar
//
//  Created by Ali Alhasani on 12/21/20.
//  Copyright © 2020 Ali Al-Hasani. All rights reserved.
//

import Foundation
import Observation

@Observable
class MapViewModel: ParentViewModel {
    var coordinatesLastChanged = ""
    var updatedCoordinates: CampusCoordinatesModel?

    override init(dataClient: any AppDataClient = DataClient()) {
        super.init(dataClient: dataClient)
    }

    func loadGetMapData() async {
        do {
            let remote = try await dataClient.getCampusMapCoordinates(cacheLastChanged: coordinatesLastChanged)
            let serverTime = remote.model.updateTime
            guard !serverTime.isEmpty, serverTime != coordinatesLastChanged else { return }
            persistCoordinateCache(model: remote.model, rawData: remote.rawData)
        } catch {
            // silently fail — map loads from local cache
        }
    }

    private func persistCoordinateCache(model: CampusCoordinatesModel, rawData: Data) {
        Data.saveJson(data: rawData, toFilename: "Campus_Map_Coord")
        updatedCoordinates = model
    }
}
