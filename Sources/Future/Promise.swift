//===--- Promise.swift ------------------------------------------------------===//
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
import Boilerplate
import Result
import ExecutionContext

public class Promise<V> : MutableFutureType {
    public typealias Value = V
    
    private let _future:MutableFuture<V>
    
    public var future:Future<V> {
        get {
            return _future
        }
    }
    
    public init(context:ExecutionContextProtocol) {
        _future = MutableFuture(context: context)
    }
    
    public convenience init() {
        self.init(context: immediate)
    }
    
    public func tryComplete<E : Error>(result:Result<Value, E>) -> Bool {
        return _future.tryComplete(result: result)
    }
}
