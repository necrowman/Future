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

```swift
import Future

let f = Future<Int>(value: 2)

f.onComplete { result in
	//complete block executes after .onSuccess or .onFailure execution
}

f.onSuccess { value in
	//successful block execution
}

f.onFailure { _ in
	//failure block execution
}
```

#### Basic usage

#####  Example with Alamofire (using promise)

```swift
import Future
import Alamofire
...
func useAlamofire(url: String) -> Future<String> {
    let promise = Promise<String>()                //create Promise        
    Alamofire.request(url).responseString { (response) in 
        switch response.result {
        case .success(let answer):
            try! promise.success(value: answer)    //throw promise.success
        case .failure(let error):
            try! promise.fail(error: error)        //throw promise.fail
        }    
    }
    return promise.future
}
...
useAlamofire(url: "https://httpbin.org/ip")
.onSuccess { result in                             //success event observing
    print("result: => ", result)
}.onFailure { (error) in                           //failure event observing
    print("error: => ", error.localizedDescription)
}.onComplete { (result) in                         //after success or failure event observing
    print("completed with value: \(result.value ?? "") and error \(result.error?.localizedDescription ?? "")" )
}
```

## Roadmap

* v0.2.0-alpha.2: stable release (once we will see that no issues are coming)

## Changelog

You can view the [CHANGELOG](./CHANGELOG.md) as a separate document [here](./CHANGELOG.md).

## Contributing

To get started, <a href="https://www.clahub.com/agreements/crossroadlabs/Future">sign the Contributor License Agreement</a>.

## [![Crossroad Labs](http://i.imgur.com/iRlxgOL.png?1) by Crossroad Labs](http://www.crossroadlabs.xyz/)