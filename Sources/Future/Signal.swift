//===--- Signal.swift ------------------------------------------------------===//
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
import Event

public extension SignalStream {
    public func flatMap<A, F : FutureProtocol>(_ f:@escaping (Payload)->F) -> SignalStream<Result<A, AnyError>> where F.Value == A {
        let context = self.context
        return SignalStream<Result<A, AnyError>>(context: context, advise: { fun in
            self.chain { sig, payload in
                f(payload).settle(in: context).onComplete { (result:Result<A, AnyError>) in
                    fun((sig, result))
                }
            }
        })
    }
}
