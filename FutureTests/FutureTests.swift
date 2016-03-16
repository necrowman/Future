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
        
        let f3 = f2.recover { e in
            return "recovered"
        }
        
        let f4 = f2.recover { (e:TestError) in
            return "678"
        }
        
        let f5 = f2.recoverWith { e in
            return future {
                return "819"
            }
        }
        
        f3.flatMap { str in
            return Int(str)
        }.onFailure { (e:Error) in
            print("recovered 3:", e)
        }
        
        f4.flatMap { str in
            return Int(str)
        }.onSuccess { value in
            print("recovered 4:", value)
        }
        
        f5.flatMap { str in
            return Int(str)
        }.onSuccess { value in
            print("recovered 5:", value)
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
