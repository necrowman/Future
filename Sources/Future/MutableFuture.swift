//===--- MutableFuture.swift ------------------------------------------------------===//
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

public protocol MutableFutureType {
    associatedtype Value
    
    func tryComplete<E : Error>(result:Result<Value, E>) -> Bool
}

internal class MutableFuture<V> : Future<V>, MutableFutureType {
    internal override init(context:ExecutionContextProtocol) {
        super.init(context: context)
    }
    
    internal func tryComplete<E : Error>(result:Result<Value, E>) -> Bool {
        if nil != self.result {
            return false
        }
        
        self.result = result.asAnyError()
        return true
    }
}

public extension MutableFutureType {
    func complete<E : Error>(result:Result<Value, E>) throws {
        if !tryComplete(result: result) {
            throw FutureError.alreadyCompleted
        }
    }
    
    func trySuccess(value:Value) -> Bool {
        return tryComplete(result: Result<Value, AnyError>(value:value))
    }
    
    func success(value:Value) throws {
        if !trySuccess(value: value) {
            throw FutureError.alreadyCompleted
        }
    }
    
    func tryFail(error:Error) -> Bool {
        return tryComplete(result: Result(error: AnyError(error)))
    }
    
    func fail(error:Error) throws {
        if !tryFail(error: error) {
            throw FutureError.alreadyCompleted
        }
    }
    
    
    /// safe to be called several times
    func completeWith<F: FutureProtocol>(future:F) where F.Value == Value {
        future.onComplete { (result:Result<Value, AnyError>) in
            //yes, suppress (we might have multiple complete with statements)
            let _ = self.tryComplete(result: result)
        }
    }
}
