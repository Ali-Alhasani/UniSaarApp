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
    override init(dataClient: DataClient = DataClient()) {
        super.init(dataClient: dataClient)
    }

    func loadGetMapData () {
        showLoadingIndicator.value = true
        dataClient.getCampusMapCoordinates(completion: {  result in
            switch result {
            case .success(let coordinates):
                // only update the cache if the api update time is more recent
                if coordinates.updateTime != self.coordinatesLastChanged {
                    self.updateCoordinateCache(newCoordinates: coordinates.mapInfo)
                }
            case .failure:
                break
            }
        }, cacheLastChanged: coordinatesLastChanged)

    }
    func updateCoordinateCache(newCoordinates: JSON) {
        DispatchQueue.main.async {
            if let  filePath = Bundle.main.url(forResource: "Campus_Map_Coord", withExtension: "json") {
                do {
                    let data = try newCoordinates.rawData()
                    try data.write(to: filePath, options: [])
                } catch {
                    print(error)
                }
            }
        }
    }
}
