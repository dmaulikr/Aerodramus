//
//  Promise+After.swift
//  Aerodramus
//
//  Created by 金晓龙 on 2017/8/2.
//  Copyright © 2017年 Zodiac.com. All rights reserved.
//

import Foundation

public extension Promise {
    
    public func after(seconds: TimeInterval) -> Promise {
        
        return Promise({ deferred in
            self.done({ result in
                let deadline = DispatchTime.now() + seconds
                DispatchQueue.global().asyncAfter(deadline: deadline, execute: {
                    deferred.resolve(result)
                })
            }).fail({ error in
                let deadline = DispatchTime.now() + seconds
                DispatchQueue.global().asyncAfter(deadline: deadline, execute: {
                    deferred.reject(error)
                })
            }).progress({ progress in
                let deadline = DispatchTime.now() + seconds
                DispatchQueue.global().asyncAfter(deadline: deadline, execute: {
                    deferred.notify(progress)
                })
            })

            
        })
        
    }
    
}
