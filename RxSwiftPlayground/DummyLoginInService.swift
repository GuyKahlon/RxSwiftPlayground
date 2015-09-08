//
//  DummyLoginInService.swift
//  RxSwiftPlayground
//
//  Created by Guy Kahlon on 9/8/15.
//  Copyright © 2015 GuyKahlon. All rights reserved.
//

import Foundation


typealias DummyResponse = Bool
typealias DummyCompletionBlock = (DummyResponse) -> Void

class DummyLoginInService{
    
    class func login(email: String, password: String, completion: DummyCompletionBlock){
        
        let delayTime = dispatch_time(DISPATCH_TIME_NOW, Int64(2 * Double(NSEC_PER_SEC)))
        dispatch_after(delayTime, dispatch_get_main_queue()) {
            let success = email == "email@test.com" && password == "1234"
            completion(success);
        }
    }
}