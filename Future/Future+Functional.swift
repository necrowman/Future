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

public extension FutureType {
    public func onComplete<E: ErrorProtocol>(callback: Result<Value, E> -> Void) -> Self {
        return onComplete(contextSelector(continuation: true), callback: callback)
    }
    
    public func onSuccess(context: ExecutionContextType = contextSelector(continuation: true), f: Value -> Void) {
        self.onComplete(context) { (result:Result<Value, AnyError>) in
            result.analysis(ifSuccess: { value in
                f(value)
            }, ifFailure: {_ in})
        }
    }
    
    public func onFailure<E : ErrorProtocol>(context: ExecutionContextType = contextSelector(continuation: true), f: E -> Void) {
        self.onComplete(context) { (result:Result<Value, E>) in
            result.analysis(ifSuccess: {_ in}, ifFailure: {error in
                f(error)
            })
        }
    }
    
    public func onFailure(context: ExecutionContextType = contextSelector(continuation: true), f: ErrorProtocol -> Void) {
        self.onComplete(context) { (result:Result<Value, AnyError>) in
            result.analysis(ifSuccess: {_ in}, ifFailure: {error in
                f(error.error)
            })
        }
    }
}

public extension FutureType {
    public func map<B>(context:ExecutionContextType = contextSelector(continuation: true), f:(Value) throws -> B) -> Future<B> {
        let future = MutableFuture<B>()
        
        self.onComplete(context) { (result:Result<Value, AnyError>) in
            let result = result.flatMap { value in
                materializeAny {
                    try f(value)
                }
            }
            try! future.complete(result)
        }
        
        return future
    }
    
    public func flatMap<B, F : FutureType where F.Value == B>(context:ExecutionContextType = contextSelector(continuation: true), f:(Value) -> F) -> Future<B> {
        let future = MutableFuture<B>()
        
        self.onComplete(context) { (result:Result<Value, AnyError>) in
            result.analysis(ifSuccess: { value in
                let b = f(value)
                b.onComplete(immediate) { (result:Result<B, AnyError>) in
                    try! future.complete(result)
                }
            }, ifFailure: { error in
                try! future.fail(error)
            })
        }
        
        return future
    }
    
    public func flatMap<B, E : ErrorProtocol>(context:ExecutionContextType = contextSelector(continuation: true), f:(Value) -> Result<B, E>) -> Future<B> {
        let future = MutableFuture<B>()
        
        self.onComplete(context) { (result:Result<Value, AnyError>) in
            result.analysis(ifSuccess: { value in
                let b = f(value)
                try! future.complete(b)
            }, ifFailure: { error in
                try! future.fail(error)
            })
        }
        
        return future
    }
    
    public func flatMap<B>(context:ExecutionContextType = contextSelector(continuation: true), f:(Value) -> B?) -> Future<B> {
        let future = MutableFuture<B>()
        
        self.onComplete(context) { (result:Result<Value, AnyError>) in
            let result:Result<B, AnyError> = result.flatMap { value in
                guard let b = f(value) else {
                    return Result(error: AnyError(Error.MappedNil))
                }
                return Result(value: b)
            }
            try! future.complete(result)
        }
        
        return future
    }
    
    public func recover<E : ErrorProtocol>(context:ExecutionContextType = contextSelector(continuation: true), f:(E) throws ->Value) -> Future<Value> {
        let future = MutableFuture<Value>()
        
        self.onComplete(context) { (result:Result<Value, E>) in
            let result = result.flatMapError { error in
                return materializeAny {
                    try f(error)
                }
            }
            future.tryComplete(result)
        }
        
        // if first one didn't match this one will be called next
        future.completeWith(context, f:self)
        
        return future
    }
    
    public func recover(context:ExecutionContextType = contextSelector(continuation: true), f:(ErrorProtocol) throws ->Value) -> Future<Value> {
        let future = MutableFuture<Value>()
        
        self.onComplete(context) { (result:Result<Value, AnyError>) in
            let result = result.flatMapError { error in
                return materializeAny {
                    try f(error.error)
                }
            }
            future.tryComplete(result)
        }
        
        // if first one didn't match this one will be called next
        future.completeWith(context, f:self)
        
        return future
    }
    
    public func recoverWith<E : ErrorProtocol>(context:ExecutionContextType = contextSelector(continuation: true), f:(E) -> Future<Value>) -> Future<Value> {
        let future = MutableFuture<Value>()
        
        self.onComplete(context) { (result:Result<Value, AnyError>) in
            guard let mapped:Result<Value, E> = result.tryAsError() else {
                try! future.complete(result)
                return
            }
            
            mapped.analysis(ifSuccess: { _ in
                try! future.complete(result)
            }, ifFailure: { e in
                future.completeWith(immediate, f:f(e))
            })
        }
        
        return future
    }
    
    public func recoverWith(context:ExecutionContextType = contextSelector(continuation: true), f:(ErrorProtocol) -> Future<Value>) -> Future<Value> {
        let future = MutableFuture<Value>()
        
        self.onComplete(context) { (result:Result<Value, AnyError>) in
            guard let mapped:Result<Value, AnyError> = result.tryAsError() else {
                try! future.complete(result)
                return
            }
            
            mapped.analysis(ifSuccess: { _ in
                try! future.complete(result)
                }, ifFailure: { e in
                    future.completeWith(immediate, f:f(e.error))
            })
        }
        
        return future
    }
}