//
//  UIProgressView+Promise.swift
//  Aerodramus
//
//  Created by 金晓龙 on 2017/7/30.
//  Copyright © 2017年 Zodiac.com. All rights reserved.
//

import UIKit.UIProgressView

public extension UIProgressView {
    
    public func prms_bind<T>(with promise: Promise<T>) {
        promise.always({ [weak self] _,_ in
            self?.progress = 1
        }).progress({ [weak self] progress in
            if let progress = progress {
                self?.progress = Float(progress.fractionCompleted)
            }
        })
    }
    
}
