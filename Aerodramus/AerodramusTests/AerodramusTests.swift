//
//  AerodramusTests.swift
//  AerodramusTests
//
//  Created by 金晓龙 on 2017/7/28.
//  Copyright © 2017年 Zodiac.com. All rights reserved.
//

import XCTest
@testable import Aerodramus

class AerodramusTests: XCTestCase {
    
    override func setUp() {
        super.setUp()
        // Put setup code here. This method is called before the invocation of each test method in the class.
    }
    
    override func tearDown() {
        // Put teardown code here. This method is called after the invocation of each test method in the class.
        super.tearDown()
    }
    
    func testExample() {
        // This is an example of a functional test case.
        // Use XCTAssert and related functions to verify your tests produce the correct results.
        urlSesionTest()
    }
    
    func urlSesionTest() {
        if let url = URL(string: "https://cdn.pixabay.com/photo/2017/07/02/00/43/bundestag-2463236_1280.jpg") {
            DispatchQueue(label: "com.zodiac.aerodramusTest").async {
                let session = URLSession(configuration: URLSessionConfiguration.default)
                let pms = session.prms_dataTask(with: url)
                pms.done({ response in
                    print(response)
                }).fail({ error in
                    print(error)
                }).progress({ progress in
                    print(progress)
                })
    
            }
        }
        Thread.sleep(forTimeInterval: 10000)
    }
    
    func testPerformanceExample() {
        // This is an example of a performance test case.
        self.measure {
            // Put the code you want to measure the time of here.
        }
    }
    
}
