//
//  UIActivityIndicatorView+Promise.swift
//  Aerodramus
//
//  Created by 金晓龙 on 2017/7/30.
//  Copyright © 2017年 Zodiac.com. All rights reserved.
//

import UIKit.UIActivityIndicatorView

public extension UIActivityIndicatorView {
    
    public func prms_bind<T>(with promise: Promise<T>) {
        self.startAnimating()
        promise.always({ [weak self] _,_ in self?.stopAnimating() })
    }

}
