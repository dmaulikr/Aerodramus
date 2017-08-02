//
//  UIView+Promise.swift
//  Aerodramus
//
//  Created by 金晓龙 on 2017/8/1.
//  Copyright © 2017年 Zodiac.com. All rights reserved.
//

import Foundation

public extension UIView {
    
    public class func prms_animate(withDuration duration: TimeInterval, delay: TimeInterval = 0, options: UIViewAnimationOptions = [], animations: @escaping () -> Void ) -> Promise<Bool> {
        
        return Promise({ deferred in
            self.animate(withDuration: duration, delay: delay, options: options, animations: animations, completion: deferred.resolve)
        })
        
    }
    
}
