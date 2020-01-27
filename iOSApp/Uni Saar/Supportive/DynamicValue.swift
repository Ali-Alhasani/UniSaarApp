//
//  DynamicValue.swift
//  Uni Saar
//
//  Created by Ali Al-Hasani on 12/9/19.
//  Copyright © 2019 Ali Al-Hasani. All rights reserved.
//

import Foundation
//DynamicValue with observers
class Bindable<T> {
    typealias Listener = ((T) -> Void)
    var listener: Listener?
    var value: T {
        didSet {
            listener?(value)
        }
    }
    init(_ value: T) {
        self.value = value
    }
    func bind(_ listener: Listener?) {
        self.listener = listener
    }
    func bindAndFire(_ listener: Listener?) {
        self.listener = listener
        listener?(value)
    }
}
