//===--- Future.swift ------------------------------------------------------===//
//Copyright (c) 2016 Daniel Leping (dileping)
//
//Licensed under the Apache License, Version 2.0 (the "License");
//you may not use this file except in compliance with the License.
//You may obtain a copy of the License at
//
//http://www.apache.org/licenses/LICENSE-2.0
//
//Unless required by applicable law or agreed to in writing, software
//distributed under the License is distributed on an "AS IS" BASIS,
//WITHOUT WARRANTIES OR CONDITIONS OF ANY KIND, either express or implied.
//See the License for the specific language governing permissions and
//limitations under the License.
//===----------------------------------------------------------------------===//

import Foundation
import Result
import Boilerplate
import ExecutionContext

public protocol FutureType {
    typealias Value
    
    init(value:Value)
    init(error:ErrorType)
    init<E : ErrorType>(result:Result<Value, E>)
    
    func onComplete<E: ErrorType>(context: ExecutionContextType, callback: Result<Value, E> -> Void) -> Self
    
    var isCompleted:Bool {get}
}

public class Future<V> : FutureType {
    public typealias Value = V
    
    private let chain:TaskChain
    internal var result:Result<Value, AnyError>? = nil {
        didSet {
            if result != nil {
                chain.append { next in
                    return {
                        self.isCompleted = true
                        next.content?()
                    }
                }
                chain.perform()
            }
        }
    }
    
    private (set) public var isCompleted:Bool = false
    
    internal init() {
        self.chain = TaskChain()
    }
    
    public required convenience init(value:Value) {
        self.init(result: Result<Value, AnyError>(value: value))
    }
    
    public required convenience init(error:ErrorType) {
        self.init(result: Result(error: AnyError(error)))
    }
    
    public required convenience init<E : ErrorType>(result:Result<Value, E>) {
        self.init()
        self.result = result.asAnyError()
        self.isCompleted = true
    }
    
    private static func selectContext(context: ExecutionContextType) -> ExecutionContextType {
        /// some performance optimization is done here, so don't touch the ifs. ExecutionContext.current is not the fastest func
        if context.isEqualTo(immediate) {
            return ExecutionContext.current
        } else {
            let current = ExecutionContext.current
            if current.isEqualTo(context) {
                return immediate
            } else {
                return context
            }
        }
    }
    
    public func onComplete<E: ErrorType>(context: ExecutionContextType, callback: Result<Value, E> -> Void) -> Self {
        
        let context = Future.selectContext(context)
        
        admin.execute {
            
            if self.isCompleted {
                let mapped:Result<Value, E>? = self.result!.tryAsError()
                if let result = mapped {
                    context.execute {
                        callback(result)
                    }
                }
            } else {
                self.chain.append { next in
                    return {
                        let mapped:Result<Value, E>? = self.result!.tryAsError()
                        
                        if let result = mapped {
                            context.execute {
                                callback(result)
                                next.content?()
                            }
                        } else {
                            context.execute {
                                next.content?()
                            }
                        }
                    }
                }
            }
        }
        
        return self
    }
}

public func future<T>(context:ExecutionContextType = contextSelector(continuation: false), task:() throws ->T) -> Future<T> {
    let future = MutableFuture<T>()
    
    context.execute {
        do {
            let value = try task()
            try! future.success(value)
        } catch let e {
            try! future.fail(e)
        }
    }
    
    return future
}

public func future<T, E : ErrorType>(context:ExecutionContextType = contextSelector(continuation: false), task:() -> Result<T, E>) -> Future<T> {
    let future = MutableFuture<T>()
    
    context.execute {
        let result = task()
        try! future.complete(result)
    }
    
    return future
}

public func future<T, F : FutureType where F.Value == T>(context:ExecutionContextType = contextSelector(continuation: false), task:() -> F) -> Future<T> {
    let future = MutableFuture<T>()
    
    context.execute {
        future.completeWith(f: task())
    }
    
    return future
}