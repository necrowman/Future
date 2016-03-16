//===--- TaskChain.swift ------------------------------------------------------===//
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
import ExecutionContext

internal let admin = ExecutionContext(kind: .Serial)

internal class TaskChain {
    private let head:SafeTask
    
    private var nextTail:MutableAnyContainer<SafeTask?>
    
    init() {
        let tail = MutableAnyContainer<SafeTask?>(nil)
        head = {
            tail.content?()
        }
        nextTail = tail
    }
    
    func perform() {
        head()
    }
    
    /// you have to handle calling next yourself
    func append(f:(AnyContainer<SafeTask?>)->SafeTask) {
        let tail = MutableAnyContainer<SafeTask?>(nil)
        let task = f(tail)
        admin.execute {
            self.nextTail.content = task
            self.nextTail = tail
        }
    }
}