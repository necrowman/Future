//
//  FutureTests.swift
//  FutureTests
//
//  Created by Daniel Leping on 3/12/16.
//  Copyright © 2016 Crossroad Labs, LTD. All rights reserved.
//

import XCTest

import XCTest3
import Result
import Boilerplate
import ExecutionContext

/*@testable*/ import Future

private enum TestError : ErrorProtocol {
    case Recoverable
    case Fatal
}

func fibonacci(n: Int) -> Int {
    switch n {
    case 0...1:
        return n
    default:
        return fibonacci(n - 1) + fibonacci(n - 2)
    }
}

/**
 * This extension contains utility methods used in the tests above
 */
extension XCTestCase {
    func expectation() -> XCTestExpectation {
        return self.expectation(withDescription: "no description")
    }
    
    func failingFuture<U>() -> Future<U> {
        return future {
            usleep(arc4random_uniform(100))
            throw TestError.Recoverable
        }
    }
    
    func succeedingFuture<U>(val: U) -> Future<U> {
        return future {
            usleep(arc4random_uniform(100))
            return val
        }
    }
}


class FutureTests: XCTestCase {
    
    func testCompletedFuture() {
        let f = Future<Int>(value: 2)
        
        let completeExpectation = self.expectation(withDescription:"immediate complete")
        
        f.onComplete { (result:Result<Int,AnyError>) in
            XCTAssert(result.value != nil)
            completeExpectation.fulfill()
        }
        
        let successExpectation = self.expectation(withDescription: "immediate success")
        
        f.onSuccess { value in
            XCTAssert(value == 2, "Computation should be returned")
            successExpectation.fulfill()
        }
        
        f.onFailure { _ in
            XCTFail("failure block should not get called")
        }
        
        self.waitForExpectations(withTimeout:2, handler: nil)
    }
    
    func testCompletedVoidFuture() {
        let f = Future<Void>(value: ())
        XCTAssert(f.isCompleted, "void future should be completed")
    }
    
    func testFailedFuture() {
        let error = NSError(domain: "test", code: 0, userInfo: nil)
        let f = Future<Void>(error: error)
        
        let completeExpectation = self.expectation(withDescription: "immediate complete")
        
        f.onComplete { (result:Result<Void, NSError>) in
            switch result {
            case .Success(_):
                XCTAssert(false)
            case .Failure(let err):
                print("Error: \(err)")
                XCTAssertEqual(err, error)
            }
            completeExpectation.fulfill()
        }
        
        let failureExpectation = self.expectation(withDescription: "immediate failure")
        
        f.onFailure { (err:NSError) in
            print("Error 2: \(err)")
            XCTAssert(err.isEqual(error))
            failureExpectation.fulfill()
        }
        
        f.onSuccess { value in
            XCTFail("success should not be called")
        }
        
        self.waitForExpectations(withTimeout:2, handler: nil)
    }
    
    func testFutureBasic() {
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
        
        let f6 = f2.recoverWith { e in
            return Future(value: "347")
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
        
        let exp = self.expectation(withDescription: "6")
        
        f6.flatMap { str in
            return Int(str)
            }.onSuccess { value in
                print("recovered 6:", value)
                exp.fulfill()
        }
        
        self.waitForExpectations(withTimeout: 2, handler: nil)
        
        // This is an example of a functional test case.
        // Use XCTAssert and related functions to verify your tests produce the correct results.
    }
    
    func testControlFlowSyntax() {
        
        let f = future {fibonacci(10)}
        let e = self.expectation(withDescription: "the computation succeeds")
        
        f.onSuccess { value in
            XCTAssert(value == 55)
            e.fulfill()
        }
        
        self.waitForExpectations(withTimeout: 10, handler: nil)
    }
    
    func testControlFlowSyntaxWithError() {
        
        let f : Future<String?> = future {
            throw TestError.Recoverable
        }
        
        let failureExpectation = self.expectation(withDescription: "failure expected")
        
        f.onFailure { error in
            XCTAssert(error as? TestError == .Recoverable)
            failureExpectation.fulfill()
        }
        
        self.waitForExpectations(withTimeout:3, handler: nil)
    }
    
//    func testAutoClosure() {
//        let names = ["Steve", "Tim"]
//        
//        let f = future(names.count)
//        let e = self.expectation()
//        
//        f.onSuccess { value in
//            XCTAssert(value == 2)
//            e.fulfill()
//        }
//        
//        self.waitForExpectations(withTimeout: 2, handler: nil)
//        
//        let e1 = self.expectation()
//        Future<Int>(value: fibonacci(10)).onSuccess { value in
//            XCTAssert(value == 55);
//            e1.fulfill()
//        }
//        
//        self.waitForExpectationsWithTimeout(2, handler: nil)
//    }

//    func testAutoClosureWithResult() {
//        let f = future(Result<Int, NoError>(value:2))
//        let e = self.expectation()
//        
//        f.onSuccess { value in
//            XCTAssert(value == 2)
//            e.fulfill()
//        }
//        
//        self.waitForExpectations(withTimeout: 2, handler: nil)
//        
//        let f1 = future(Result<Int, TestError>(error: .Recoverable))
//        let e1 = self.expectation()
//        
//        f1.onFailure { (error: TestError) in
//            XCTAssert(error == TestError.Recoverable)
//            e1.fulfill()
//        }
//        
//        self.waitForExpectations(withTimeout: 2, handler: nil)
//    }
    
    
    func testCustomExecutionContext() {
        let f = future(immediate) {
            fibonacci(10)
        }
        
        let e = self.expectation(withDescription: "immediate success expectation")
        
        f.onSuccess(immediate) { value in
            e.fulfill()
        }
        
        self.waitForExpectations(withTimeout: 0, handler: nil)
    }
    
    func testMainExecutionContext() {
        let e = self.expectation()
        
        future { _ -> Int in
            XCTAssert(!Thread.isMain)
            return 1
        }.onSuccess { value in
            XCTAssert(Thread.isMain)
            e.fulfill()
        }
        
        self.waitForExpectations(withTimeout: 2, handler: nil)
    }
    
    func testDefaultCallbackExecutionContextFromMain() {
        let f = Future<Int>(value: 1)
        let e = self.expectation()
        f.onSuccess { _ in
            XCTAssert(Thread.isMain, "the callback should run on main")
            e.fulfill()
        }
        
        self.waitForExpectations(withTimeout: 2, handler: nil)
    }
    
    func testDefaultCallbackExecutionContextFromBackground() {
        let f = Future<Int>(value: 1)
        let e = self.expectation()
        global.execute {
            f.onSuccess { _ in
                XCTAssert(!Thread.isMain, "the callback should not be on the main thread")
                e.fulfill()
            }
        }
        
        self.waitForExpectations(withTimeout: 2, handler: nil)
    }

//    func testPromoteErrorNoSuchElement() {
//        let f: Future<Int, BrightFuturesError<TestError>> = future(3).filter { _ in false }.promoteError()
//        
//        let e = self.expectation()
//        f.onFailure { err in
//            XCTAssert(err == BrightFuturesError<TestError>.NoSuchElement)
//            e.fulfill()
//        }
//        
//        self.waitForExpectationsWithTimeout(2, handler: nil)
//    }

    // MARK: Functional Composition
    
//    func testAndThen() {
//        
//        var answer = 10
//        
//        let e = self.expectation()
//        
//        let f = Future<Int>(value: 4)
//        let f1 = f.andThen { result in
//            if let val = result.value {
//                answer *= val
//            }
//        }
//        
//        let f2 = f1.andThen { result in
//            answer += 2
//        }
//        
//        f1.onSuccess { fval in
//            f1.onSuccess { f1val in
//                f2.onSuccess { f2val in
//                    
//                    XCTAssertEqual(fval, f1val, "future value should be passed transparently")
//                    XCTAssertEqual(f1val, f2val, "future value should be passed transparantly")
//                    
//                    e.fulfill()
//                }
//            }
//        }
//        
//        self.waitForExpectations(withTimeout: 20, handler: nil)
//        
//        XCTAssertEqual(42, answer, "andThens should be executed in order")
//    }
    
    func testSimpleMap() {
        let e = self.expectation()
        
        func divideByFive(i: Int) -> Int {
            return i / 5
        }
        
        Future<Int>(value: fibonacci(10)).map(f: divideByFive).onSuccess { val in
            XCTAssertEqual(val, 11, "The 10th fibonacci number (55) divided by 5 is 11")
            e.fulfill()
            return
        }
        
        self.waitForExpectations(withTimeout: 2, handler: nil)
    }

    func testMapSuccess() {
        let e = self.expectation()
        
        // Had to split here to lets. It feels like swift compiler has a bug and can not do this chain in full
        // Hopefully they will resolve the issue in the next versions and soon enough
        // No details (like particular types) were added on top though
        // Actually it still is quite a rare case when you map a just created future
        future {
            fibonacci(10)
        }.map { value -> String in
            if value > 5 {
                return "large"
            }
            return "small"
        }.map { sizeString -> Bool in
            return sizeString == "large"
        }.onSuccess { numberIsLarge in
            XCTAssert(numberIsLarge)
            e.fulfill()
        }
        
        self.waitForExpectations(withTimeout: 2, handler: nil)
    }
    
    func testMapFailure() {
        
        let e = self.expectation()
        
        future { () -> Result <Int, NSError> in
            Result(error: NSError(domain: "Tests", code: 123, userInfo: nil))
        }.map { number in
            XCTAssert(false, "map should not be evaluated because of failure above")
        }.map { number in
            XCTAssert(false, "this map should also not be evaluated because of failure above")
        }.onFailure { (error:NSError) -> Void in
            XCTAssert(error.domain == "Tests")
            e.fulfill()
        }
        
        self.waitForExpectations(withTimeout: 2, handler: nil)
    }
    
    func testRecover() {
        let e = self.expectation()
        Future<Int>(error: TestError.Recoverable).recover { _ in
            return 3
        }.onSuccess { val in
            XCTAssertEqual(val, 3)
            e.fulfill()
        }
        
//        let recov: () -> Int = {
//            return 5
//        }
//        
//        let e1 = self.expectation()
//        (Future<Int>(error: TestError.Recoverable) ?? recov()).onSuccess { value in
//            XCTAssert(value == 5)
//            e1.fulfill()
//        }
        
        self.waitForExpectations(withTimeout: 2, handler: nil)
    }
    
    func testSkippedRecover() {
        let e = self.expectation()
        
        future {
            3
        }.recover { _ in
            XCTFail("recover task should not be executed")
            return 5
        }.onSuccess { value in
            XCTAssert(value == 3)
            e.fulfill()
        }
        
//        let e1 = self.expectation()
//        
//        
//        let recov: () -> Int = {
//            XCTFail("recover task should not be executed")
//            return 5
//        }
//        
//        (future(3) ?? recov()).onSuccess { value in
//            XCTAssert(value == 3)
//            e1.fulfill()
//        }
        
        self.waitForExpectations(withTimeout: 2, handler: nil)
    }

}
