//===--- Future+Sequence.swift ------------------------------------------------------===//
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

import ExecutionContext

private extension Sequence {
    var _contexted:ContextedSequence<Self> {
        return ContextedSequence(sequence: self, context: immediate)
    }
}

public extension Sequence where Self : ExecutionContextTenantProtocol {
    public var context:ExecutionContextProtocol {
        return immediate
    }
}

public extension Sequence where Self : MovableExecutionContextTenantProtocol {
    public typealias SettledTenant = ContextedSequence<Self>
    
    public func settle(in context:ExecutionContextProtocol) -> ContextedSequence<Self> {
        return ContextedSequence(sequence: self, context: context)
    }
}

extension Array : MovableExecutionContextTenantProtocol {
}

extension Dictionary : MovableExecutionContextTenantProtocol  {
}

public struct ContextedSequence<S : Sequence> {
    fileprivate let _s:S
    fileprivate let _c:ExecutionContextProtocol
    
    fileprivate init(sequence:S, context:ExecutionContextProtocol) {
        _s = sequence
        _c = context
    }
}

public extension ContextedSequence where S.Iterator.Element : FutureProtocol {
    public typealias A = S.Iterator.Element.Value
    
    public func fold<Z>(_ z:Z, _ f: @escaping (Z, A)->Z) -> Future<Z> {
        return _s.reduce(Future<Z>(context: _c, value:z)) { z, a in
            z.flatMap { z in
                a.map { a in
                    f(z, a)
                }
            }
        }
    }
    
    public func foldFlat<Z, R : FutureProtocol>(_ z:Z, _ f: @escaping (Z, A)->R) -> Future<Z> where R.Value == Z {
        return _s.reduce(Future<Z>(context: _c, value:z)) { z, a in
            z.flatMap { z in
                a.flatMap { a in
                    f(z, a)
                }
            }
        }
    }
    
    public var sequence:Future<[A]> {
        return fold(Array<A>()) { z, a in
            z + [a]
        }
    }
}

public extension ContextedSequence {
    public func traverse<B>(_ f:(S.Iterator.Element)->Future<B>) -> Future<[B]> {
        return _s.map(f).settle(in: _c).sequence
    }
}



public extension Sequence where Iterator.Element : FutureProtocol {
    public func fold<Z>(_ z:Z, _ f: @escaping (Z, Iterator.Element.Value)->Z) -> Future<Z> {
        return _contexted.fold(z, f)
    }
    
    public func foldFlat<Z, R : FutureProtocol>(_ z:Z, _ f: @escaping (Z, Iterator.Element.Value)->R) -> Future<Z> where R.Value == Z {
        return _contexted.foldFlat(z, f)
    }
    
    public var sequence:Future<[Iterator.Element.Value]> {
        return _contexted.sequence
    }
}

public extension Sequence {
    public func traverse<B>(_ f:(Iterator.Element)->Future<B>) -> Future<[B]> {
        return self.map(f).sequence
    }
}
