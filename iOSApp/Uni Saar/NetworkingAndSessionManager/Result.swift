//
//  Result.swift
//  Uni Saar
//
//  Created by Ali Al-Hasani on 12/8/19.
//  Copyright © 2019 Ali Al-Hasani. All rights reserved.
//

import Foundation
enum CustomResult<T, U: Error> {
    case success(payload: T)
    case failure(U?)
}

enum CustomEmptyResult<U: Error> {
    case success
    case failure(U?)
}
