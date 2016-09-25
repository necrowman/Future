//===--- Future+InvalidationToken.swift ------------------------------------------------------===//
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

import Result
import Boilerplate

public extension Future {
    @discardableResult
    public func onComplete(token:InvalidationToken, _ callback: @escaping (Result<Value, AnyError>) -> Void) -> Self {
        return self.onComplete(token.closure(callback))
    }
}

public extension FutureProtocol {
    @discardableResult
    public func onComplete<E: Error>(token:InvalidationToken, _ callback: @escaping (Result<Value, E>) -> Void) -> Self {
        return self.onComplete(token.closure(callback))
    }
    
    @discardableResult
    public func onSuccess(token:InvalidationToken, _ f:@escaping (Value) -> Void) -> Self {
        return self.onSuccess(token.closure(f))
    }
    
    @discardableResult
    public func onFailure<E : Error>(token:InvalidationToken, _ f:@escaping (E) -> Void) -> Self{
        return self.onFailure(token.closure(f))
    }
    
    @discardableResult
    public func onFailure(token:InvalidationToken, _ f:@escaping (Error) -> Void) -> Self {
        return self.onFailure(token.closure(f))
    }
}
