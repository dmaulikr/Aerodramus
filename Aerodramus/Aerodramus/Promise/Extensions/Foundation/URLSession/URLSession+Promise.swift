//
//  URLSession+Promise.swift
//  Aerodramus
//
//  Created by 金晓龙 on 2017/7/30.
//  Copyright © 2017年 Zodiac.com. All rights reserved.
//

import Foundation

public extension URLSession {
    
    public func prms_dataTask(with url: URL) -> URLDataPromise {
        return URLDataPromise({ self.dataTask(with: url, completionHandler: $0) })
    }
    
    public func prms_dataTask(with request: URLRequest) -> URLDataPromise {
        return URLDataPromise({ self.dataTask(with: request, completionHandler: $0) })
    }
    
}

