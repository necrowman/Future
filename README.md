[![by Crossroad Labs](./header.png)](http://www.crossroadlabs.xyz/)

# Future

![🐧 linux: ready](https://img.shields.io/badge/%F0%9F%90%A7%20linux-ready-red.svg)
[![GitHub license](https://img.shields.io/badge/license-Apache%202.0-lightgrey.svg?style=flat)](https://raw.githubusercontent.com/reactive-swift/Future/master/LICENSE)
[![Build Status](https://travis-ci.org/reactive-swift/Future.svg?branch=master)](https://travis-ci.org/reactive-swift/Future)
[![GitHub release](https://img.shields.io/github/release/reactive-swift/Future.svg)](https://github.com/reactive-swift/Future/releases)
[![Carthage compatible](https://img.shields.io/badge/Carthage-compatible-4BC51D.svg?style=flat)](https://github.com/Carthage/Carthage)
![Platform OS X | iOS | tvOS | watchOS | Linux](https://img.shields.io/badge/platform-Linux%20%7C%20OS%20X%20%7C%20iOS%20%7C%20tvOS%20%7C%20watchOS-orange.svg)

## Futures and promises. All functional, inspired by Scala Futures

## Goals

[<img align="left" src="https://raw.githubusercontent.com/crossroadlabs/Express/master/logo-full.png" hspace="20" height=128>](https://github.com/reactive-swift/Future) Future library was mainly introduced to fulfill the needs of [Swift Express](https://github.com/crossroadlabs/Express) - web application server side framework for Swift.

Still we hope it will be useful for everybody else.

[Happy futuring ;)](#examples)

## Features (Must be edited for Future)

- [x] Feature 1
	- [x] subfeature 1.1
	- [x] subfeature 1.2
- [x] Feature 2

## Getting started

### Installation

#### [Package Manager](https://swift.org/package-manager/)

Add the following dependency to your [Package.swift](https://github.com/apple/swift-package-manager/blob/master/Documentation/Package.swift.md):

```swift
.Package(url: "https://github.com/reactive-swift/Future.git", majorVersion: 0)
```

Run ```swift build``` and build your app. Package manager is supported on OS X, but it's still recommended to be used on Linux only.

#### [Carthage](https://github.com/Carthage/Carthage)
Add the following to your [Cartfile](https://github.com/Carthage/Carthage/blob/master/Documentation/Artifacts.md#cartfile):

```
github "reactive-swift/Future"
```

Run `carthage update` and follow the steps as described in Carthage's [README](https://github.com/Carthage/Carthage#adding-frameworks-to-an-application).

#### Manually
1. Download and drop ```/Future``` folder in your project.  
2. Congratulations!

### Examples

#### Initialization Future:

##### Initialization Future with value:

```swift
let f1 = Future(value: 2) // Creates future with value 2
f1.onSuccess{ val in
    print(val) // Wil be printed immediately
}
```

##### Initialization Future with error:

```swift
let f2 = Future<Int>(error: CustomErrors.err1)//Creates failed future with given error
f2.onFailure { err in
    print(err)
}
```

##### Initialization Future via “future” function

```swift
let f3 = future { () -> Int in 
    usleep(1100000) // Sleeps 1.1 sec
    return 10
} // Creates future which will be asyncronously resolved by value 10

f3.onSuccess{ val in
    print(val) // Will be printed asyncronusly in 1 sec
}

let f4 = future{ () -> Int in
    sleep(1) // Sleeps 1 sec
    throw CustomErrors.err2
} // Creates future which will be asyncronously resolved by value 10
f4.onFailure{ err in
    print(err) // Will print error asyncronusly in 1 sec
}
```

##### Initialization Future via Promise

```swift
let promise = Promise<Int>()
promise.future.onSuccess{ val in
    print(val) // Will be printed after resolving the promise
}
promise.trySuccess(value: 20) // prints "20"
```

#### Basic usage

#####  Example with Alamofire (using promise)

```swift
func useAlamofire(url: String) -> Future<String> {
    let promise = Promise<String>()             //create Promise        
    Alamofire.request(url).responseString { (response) in 
        switch response.result {
        case .success(let answer):
            try! promise.success(value: answer) //throw promise.success
        case .failure(let error):
            try! promise.fail(error: error)     //throw promise.fail
        }    
    }
    return promise.future
}
...
useAlamofire(url: "https://httpbin.org/ip")
.onSuccess { result in                          //success event observing
    print("result: => ", result)
}.onFailure { (error) in                        //failure event observing
    print("error: => ", error.localizedDescription)
}.onComplete { (result) in                      //after success or failure event observing
    print("completed with value: \(result.value ?? "") and error \(result.error?.localizedDescription ?? "")" )
}
```

##### Example with animation

```swift
extension UIView {
    class func animate(duration: TimeInterval, animations: @escaping () -> Void) -> Future<Bool> {
        let promise = Promise<Bool>()
        UIView.animate(withDuration: duration, animations: animations) { completed in
            try! promise.success(value: completed)
        }
        return promise.future
    }
}

...

func hide() {
    UIView.animate(duration: 0.3) {
        self.height.constant = 30
        self.view.layoutIfNeeded()
    }.onSuccess { completed in
        self.view.alpha = 0
    }
}

```

#### Advanced usage

##### Contexts, settled function

```swift
let fGlobal = ExecutionContext.global.sync {
    future { // create future in .global ExecutionContext;
        print(10)
    }
}
fGlobal.onComplete { val in
    print("value: ", val.value ?? 0) // proceed value in .global ExecutionContext;
}

let fMain = fGlobal.settle(in: ExecutionContext.main) // create settler for .main context
                                                      // now future can proceed in both contexts;
fMain.onComplete { val in
    print("value: ", val.value ?? 0) // proceed value in .main ExecutionContext;
}
```

## Roadmap

* v0.2.0-alpha.2: stable release (once we will see that no issues are coming)

## Changelog

You can view the [CHANGELOG](./CHANGELOG.md) as a separate document [here](./CHANGELOG.md).

## Contributing

To get started, <a href="https://www.clahub.com/agreements/crossroadlabs/Future">sign the Contributor License Agreement</a>.

## [![Crossroad Labs](http://i.imgur.com/iRlxgOL.png?1) by Crossroad Labs](http://www.crossroadlabs.xyz/)