//
//  EventTests.swift
//  Future
//
//  Created by Daniel Leping on 05/05/2016.
//  Copyright © 2016 Crossroad Labs s.r.o. All rights reserved.
//

import XCTest
import Boilerplate

import ExecutionContext
import Event
import Future

enum TestOnceError : Error {
    case some
    case substitute
}

enum TestEventString : Event {
    typealias Payload = String
    case event
}

struct TestEventGroup<E : Event> {
    internal let event:E
    
    private init(_ event:E) {
        self.event = event
    }
    
    static var string:TestEventGroup<TestEventString> {
        return TestEventGroup<TestEventString>(.event)
    }
}

class EventEmitterTest : EventEmitter {
    let dispatcher:EventDispatcher = EventDispatcher()
    let context: ExecutionContextProtocol = ExecutionContext.current
    
    func on<E : Event>(_ groupedEvent: TestEventGroup<E>) -> SignalStream<E.Payload> {
        return self.on(groupedEvent.event)
    }
    
    func once<E : Event>(_ groupedEvent: TestEventGroup<E>, failOnError:@escaping (Error)->Bool = {_ in true}) -> Future<E.Payload> {
        return self.once(groupedEvent.event, failOnError: failOnError)
    }
    
    func emit<E : Event>(_ groupedEvent: TestEventGroup<E>, payload:E.Payload) {
        self.emit(groupedEvent.event, payload: payload)
    }
}

class EventTests: XCTestCase {
    let reference = "sendme"
    
    let mQueue = ExecutionContext(kind: .serial)
    
    func testOnceSuccess() {
        
        let expectation = self.expectation(description: "success")
        
        mQueue.sync {
            let em = EventEmitterTest()
            
            let future = em.once(.string)
            
            var counter = 0
            
            future.onSuccess { s in
                XCTAssertEqual(counter, 0)
                counter += 1
                XCTAssertEqual(s, self.reference)
                expectation.fulfill()
            }
            
            future.onFailure { _ in
                XCTFail("should not reach here")
            }
            
            em.emit(.string, payload: self.reference)
            em.emit(.string, payload: self.reference + "some")
            em.emit(.error, payload: TestOnceError.some)
        }
        
        self.waitForExpectations(timeout: 1)
    }
    
    func testOnceFailed() {
        let expectation = self.expectation(description: "success")
        
        mQueue.sync {
            let em = EventEmitterTest()
            
            let future = em.once(.string) { e in
                let e = e as? TestOnceError
                return e.map({$0 == .some}) ?? false
            }
            
            var counter = 0
            
            future.onSuccess { s in
                XCTFail("should not reach here")
            }
            
            future.onFailure { e in
                XCTAssertEqual(counter, 0)
                counter += 1
                
                XCTAssertEqual(e as? TestOnceError, TestOnceError.some)
                
                expectation.fulfill()
            }
            
            em.emit(.error, payload: TestOnceError.substitute)
            em.emit(.error, payload: TestOnceError.some)
            em.emit(.string, payload: self.reference)
            em.emit(.string, payload: self.reference + "some")
        }
        
        self.waitForExpectations(timeout: 1)
    }
}

#if os(Linux)
extension EventTests {
	static var allTests : [(String, (EventTests) -> () throws -> Void)] {
		return [
			("testOnceSuccess", testOnceSuccess),
			("testOnceFailed", testOnceFailed),
		]
	}
}
#endif