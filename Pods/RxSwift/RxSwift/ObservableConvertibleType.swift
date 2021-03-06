//
//  ObservableConvertibleType.swift
//  Rx
//
//  Created by Krunoslav Zaher on 9/17/15.
//  Copyright © 2015 Krunoslav Zaher. All rights reserved.
//

import Foundation

/**
Type that can be converted to observable sequence (`Observer<E>`).
*/
public protocol ObservableConvertibleType {
    /**
    Type of elements in sequence.
    */
    typealias E
    
    /**
    Converts `self` to `Observable` sequence.
    
    - returns: Observable sequence that represents `self`.
    */
    func asObservable() -> Observable<E>
}
