//
//  URLSessionDataPromise.swift
//  Aerodramus
//
//  Created by 金晓龙 on 2017/8/1.
//  Copyright © 2017年 Zodiac.com. All rights reserved.
//

import Foundation

public enum JSONObject {
    
    case array(Array<Any>)
    
    case dictionary(Dictionary<String, Any>)
    
}

open class URLSessionDataPromise: Promise<Data> {
    
    public private(set) var task: URLSessionDataTask! = nil
    
    typealias CompletionHandler = (Data?, URLResponse?, Error?) -> Void
    
    init(_ ch: (@escaping CompletionHandler) -> URLSessionDataTask) {
        
        var task: URLSessionDataTask!
        super.init({ (resolve, reject, notify) in
            task = ch({ data, response, error in
                if let error = error {
                    reject(error)
                }
                else if let data = data, !(response is HTTPURLResponse) {
                    resolve(data)
                }
                else if let data = data, let response = response as? HTTPURLResponse, response.statusCode >= 200, response.statusCode < 300 {
                    resolve(data)
                }
                else {
                    fatalError()
//                deferred.reject(URLError.badServerResponse as! Error)
                }
            })
        })
        
        task.resume()
        self.task = task
    }
    
}

public extension URLSessionDataPromise {
    
    public var imageValue: Promise<UIImage> {
        return self.then({ data -> UIImage in
            guard let image = UIImage(data: data) else {
                //                throw URLError.invalidImageData(self.URLRequest, data)
                fatalError()
            }
            return image
        })
    }
    
    public var jsonValue: Promise<JSONObject> {
        return self.then({ data -> JSONObject in
            let json = try JSONSerialization.jsonObject(with: data, options: .allowFragments)
            if let json = json as? Array<Any> {
                return .array(json)
            }
            else if let json = json as? Dictionary<String, Any> {
                return .dictionary(json)
            }
            else {
                fatalError()
            }
        })
    }
    
    public var stringValue: Promise<String> {
        return self.then({ data -> String in
            guard let str = String(bytes: data, encoding: self.task.response?.stringEncoding ?? .utf8) else {
//                throw URLError.stringEncoding(self.URLRequest, data, self.URLResponse)
                fatalError()
            }
            return str
        })
    }
    
}


fileprivate extension URLResponse {
    
    /// Converts URLResponse.textEncodingName to String.Encoding
    fileprivate var stringEncoding: String.Encoding? {
        guard let encodingName = self.textEncodingName else {
            return nil
        }
        
        let encoding = CFStringConvertIANACharSetNameToEncoding(encodingName as CFString)
        guard encoding != kCFStringEncodingInvalidId else {
            return nil
        }
        
        return String.Encoding(rawValue: CFStringConvertEncodingToNSStringEncoding(encoding))
    }
    
}


