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
    let didUpdateCoordinates: Bindable = Bindable(JSON())

    override init(dataClient: DataClient = DataClient()) {
        super.init(dataClient: dataClient)
    }

    func loadGetMapData () {
        showLoadingIndicator.value = true
        dataClient.getCampusMapCoordinates(completion: {  result in
            switch result {
            case .success(let coordinates):
                // only update the cache if the api update time is more recent
                if coordinates.updateTime != "", coordinates.updateTime != self.coordinatesLastChanged {
                    self.updateCoordinateCache(newCoordinates: coordinates.mapInfo)
                }
            case .failure:
                break
            }
        }, cacheLastChanged: coordinatesLastChanged)

    }
    func updateCoordinateCache(newCoordinates: JSON) {
        DispatchQueue.main.async {
            do {
                try Data.saveJson(data: newCoordinates.rawData(), toFilename: "Campus_Map_Coord")
                self.didUpdateCoordinates.value = newCoordinates
            } catch {
                print(error)
            }
        }
    }
}
