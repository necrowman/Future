//
//  FutureTests.swift
//  FutureTests
//
//  Created by Daniel Leping on 3/12/16.
//  Copyright © 2016 Crossroad Labs, LTD. All rights reserved.
//

import XCTest

import Result
import Boilerplate
import ExecutionContext

/*@testable*/ import Future

private enum TestError : ErrorType {
    case Recoverable
    case Fatal
}

class FutureTests: XCTestCase {
    
    override func setUp() {
        super.setUp()
        // Put setup code here. This method is called before the invocation of each test method in the class.
    }
    
    override func tearDown() {
        // Put teardown code here. This method is called after the invocation of each test method in the class.
        super.tearDown()
    }
    
    func testExample() {
        let f = future {
            return "716"
        }
        
        f.onComplete { (result:Result<String, NoError>) in
            print("1:", result.value!)
        }
        
        f.onComplete { (result:Result<String, AnyError>) in
            print("2:", result.value!)
        }
        
        let f2:Future<String> = future {
            throw TestError.Recoverable
        }
        
        f2.onComplete { (result:Result<String, NoError>) in
            print("SHOULD NOT PRINT")
        }
        
        f2.onComplete { (result:Result<String, AnyError>) in
            print("Any:", result.error!.error)
        }
        
        f2.onComplete { (result:Result<String, TestError>) in
            print("Typed:", result.error!)
        }
        
        f2.onFailure { (e:TestError) in
            print("EEEE!!!!EEEE:", e)
        }
        
        f.flatMap { value in
            Int(value)
        }.onSuccess { value in
            print("!@#$%^&OUR INT:", value)
        }
        
        // This is an example of a functional test case.
        // Use XCTAssert and related functions to verify your tests produce the correct results.
    }
    
    func testPerformanceExample() {
        // This is an example of a performance test case.
        self.measureBlock {
            // Put the code you want to measure the time of here.
        }
    }
    
}
