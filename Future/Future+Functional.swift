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
    public func onComplete<E: ErrorType>(callback: Result<Value, E> -> Void) -> Self {
        return onComplete(contextSelector(continuation: true), callback: callback)
    }
    
    public func onSuccess(context: ExecutionContextType = contextSelector(continuation: true), f: Value -> Void) {
        self.onComplete(context) { (result:Result<Value, AnyError>) in
            result.analysis(ifSuccess: { value in
                f(value)
            }, ifFailure: {_ in})
        }
    }
    
    public func onFailure<E : ErrorType>(context: ExecutionContextType = contextSelector(continuation: true), f: E -> Void) {
        self.onComplete(context) { (result:Result<Value, E>) in
            result.analysis(ifSuccess: {_ in}, ifFailure: {error in
                f(error)
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
}