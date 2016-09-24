//===--- Future+Functional.swift ------------------------------------------------------===//
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

public extension Future {
    public func onComplete(_ callback: @escaping (Result<Value, AnyError>) -> Void) -> Self {
        return self.onCompleteInternal(callback: callback)
    }
}

public extension FutureProtocol {
    public func onSuccess(_ f: @escaping (Value) -> Void) -> Self {
        return self.onComplete { (result:Result<Value, AnyError>) in
            result.analysis(ifSuccess: { value in
                f(value)
            }, ifFailure: {_ in})
        }
    }
    
    public func onFailure<E : Error>(_ f: @escaping (E) -> Void) -> Self{
        return self.onComplete { (result:Result<Value, E>) in
            result.analysis(ifSuccess: {_ in}, ifFailure: {error in
                f(error)
            })
        }
    }
    
    public func onFailure(_ f:@escaping (Error) -> Void) -> Self {
        return self.onComplete { (result:Result<Value, AnyError>) in
            result.analysis(ifSuccess: {_ in}, ifFailure: {error in
                f(error.error)
            })
        }
    }
}

public extension FutureProtocol {
    public func map<B>(_ f:@escaping (Value) throws -> B) -> Future<B> {
        let future = MutableFuture<B>(context: self.context)
        
        let _ = self.onComplete { (result:Result<Value, AnyError>) in
            let result = result.flatMap { value -> Result<B, AnyError> in
                materializeAny {
                    try f(value)
                }
            }
            try! future.complete(result: result)
        }
        
        return future
    }
    
    public func flatMap<B, F : FutureProtocol>(_ f:@escaping (Value) -> F) -> Future<B> where F.Value == B {
        let future = MutableFuture<B>(context: self.context)
        
        let _ = self.onComplete { (result:Result<Value, AnyError>) in
            result.analysis(ifSuccess: { value in
                let b = f(value)
                let _ = b.onComplete { (result:Result<B, AnyError>) in
                    try! future.complete(result: result)
                }
            }, ifFailure: { error in
                try! future.fail(error: error)
            })
        }
        
        return future
    }
    
    public func flatMap<B, E : Error>(_ f:@escaping (Value) -> Result<B, E>) -> Future<B> {
        let future = MutableFuture<B>(context: self.context)
        
        let _ = self.onComplete { (result:Result<Value, AnyError>) in
            result.analysis(ifSuccess: { value in
                let b = f(value)
                try! future.complete(result: b)
            }, ifFailure: { error in
                try! future.fail(error: error)
            })
        }
        
        return future
    }
    
    public func flatMap<B>(_ f:@escaping (Value) -> B?) -> Future<B> {
        let future = MutableFuture<B>(context: self.context)
        
        let _ = self.onComplete { (result:Result<Value, AnyError>) in
            let result:Result<B, AnyError> = result.flatMap { value in
                guard let b = f(value) else {
                    return Result(error: AnyError(FutureError.MappedNil))
                }
                return Result(value: b)
            }
            try! future.complete(result: result)
        }
        
        return future
    }
    
    public func filter(_ f: @escaping (Value)->Bool) -> Future<Value> {
        let future = MutableFuture<Value>(context: self.context)
        
        let _ = self.onComplete { (result:Result<Value, AnyError>) in
            result.analysis(ifSuccess: { value in
                if f(value) {
                    try! future.success(value: value)
                } else {
                    try! future.fail(error: FutureError.FilteredOut)
                }
                }, ifFailure: { error in
                    try! future.fail(error: error)
            })
        }
        
        return future
    }
    
    public func filterNot(_ f:@escaping (Value)->Bool) -> Future<Value> {
        return self.filter { value in
            return !f(value)
        }
    }
    
    public func recover<E : Error>(_ f:@escaping (E) throws ->Value) -> Future<Value> {
        let future = MutableFuture<Value>(context: self.context)
        
        let _ = self.onComplete { (result:Result<Value, E>) in
            let result = result.flatMapError { error in
                return materializeAny {
                    try f(error)
                }
            }
            //yes, we want to supress double completion here
            let _ = future.tryComplete(result: result)
        }
        
        // if first one didn't match this one will be called next
        future.completeWith(future: self)
        
        return future
    }
    
    public func recover(_ f:@escaping (Error) throws ->Value) -> Future<Value> {
        let future = MutableFuture<Value>(context: self.context)
        
        let _ = self.onComplete { (result:Result<Value, AnyError>) in
            let result = result.flatMapError { error in
                return materializeAny {
                    try f(error.error)
                }
            }
            //yes, we want to supress double completion here
            let _ = future.tryComplete(result: result)
        }
        
        // if first one didn't match this one will be called next
        future.completeWith(future: self)
        
        return future
    }
    
    public func recoverWith<E : Error>(_ f:@escaping (E) -> Future<Value>) -> Future<Value> {
        let future = MutableFuture<Value>(context: self.context)
        
        let _ = self.onComplete { (result:Result<Value, AnyError>) in
            guard let mapped:Result<Value, E> = result.tryAsError() else {
                try! future.complete(result: result)
                return
            }
            
            mapped.analysis(ifSuccess: { _ -> Void in
                try! future.complete(result: result)
            }, ifFailure: { e in
                future.completeWith(future: f(e))
            })
        }
        
        return future
    }
    
    public func recoverWith(_ f:@escaping (Error) -> Future<Value>) -> Future<Value> {
        let future = MutableFuture<Value>(context: self.context)
        
        let _ = self.onComplete { (result:Result<Value, AnyError>) in
            guard let mapped:Result<Value, AnyError> = result.tryAsError() else {
                try! future.complete(result: result)
                return
            }
            
            mapped.analysis(ifSuccess: { _ -> Void in
                try! future.complete(result: result)
            }, ifFailure: { e in
                future.completeWith(future: f(e.error))
            })
        }
        
        return future
    }
    
    public func zip<B, F : FutureProtocol>(_ f:F) -> Future<(Value, B)> where F.Value == B {
        let future = MutableFuture<(Value, B)>(context: self.context)
        
        let _ = self.onComplete { (result:Result<Value, AnyError>) in
            let context = ExecutionContext.current
            
            result.analysis(ifSuccess: { first -> Void in
                let _ = f.onComplete { (result:Result<B, AnyError>) in
                    context.execute {
                        result.analysis(ifSuccess: { second in
                            try! future.success(value: (first, second))
                        }, ifFailure: { e in
                            try! future.fail(error: e.error)
                        })
                    }
                }
                
            }, ifFailure: { e in
                try! future.fail(error: e.error)
            })
        }
        
        return future
    }
}
