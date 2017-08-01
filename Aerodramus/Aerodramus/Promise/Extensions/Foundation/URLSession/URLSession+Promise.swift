//
//  URLSession+Promise.swift
//  Aerodramus
//
//  Created by 金晓龙 on 2017/7/30.
//  Copyright © 2017年 Zodiac.com. All rights reserved.
//

import Foundation

public extension URLSession {
    
    public func prms_dataTask(with url: URL) -> URLSessionPromise {
        return URLSessionPromise({ self.dataTask(with: url, completionHandler: $0) })
    }
    
    public func prms_dataTask(with request: URLRequest) -> URLSessionPromise {
        return URLSessionPromise({ self.dataTask(with: request, completionHandler: $0) })
    }
    
    public func prms_downloadTask(with url: URL) -> URLSessionPromise {
        return URLSessionPromise({ ch in
            self.downloadTask(with: url, completionHandler: { (_, response, error) in
                ch(nil, response, error)
            })
        })
    }
    
}

