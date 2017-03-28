## Changelog

* v0.2.0-alpha.2
	* swift 3.0 support (use 0.1.0 if you still need Swift 2.x)
	* Improved README
	* Added documentation
* v0.2.0-alpha.1
	* starting implementing swift 3.0 support
* v0.1.0
	* extended promises construction
	* implemented traverse
	* Future indirection to endpoints
	* implemented flatMap for SignalStreams accepting Future
	* fixed build problems; changed project sources structure; changed Linux tests; updated travis.yml
	* fixed events integration
	* enabled event tests
	* changed testFilteredOutError
	* enabled stress test
	* enabled testCompletionBlockOnMainQueue
	* enabled testRelease on Linux
	* fixed testRelease
	* fixed timeouts in tests. Yes, future resolution is indeterministic and is async
	* updated settings to recommended
	* fixed result suppression warnings
	* fixed return value checks in tests
	* @discardableResult for onSuccess/Failure/Complete
	* compatibility with invalidation tokens
	* added Linux tests for filter
	* implemented filter
	* simpler onComplete; error defaults to AnyError
	* enabled zip tests on Linux
	* easier chaining
	* added more flatMap tests
	* implemented Zip
	* fixed non releasing results of a future
	* Travis config
	* better linux support in tests
	* moved from NSError to TestError
	* better tests for linux
	* partially fixed main run loop problem in tests
	* better test for linux
	* Linux fixes for mutable pointer
	* Linux random fix
	* better unmanaged pointer obtaining
	* Linux test fixes
	* Linux fixes
	* fixed swift 3.0 compatibility
	* execution context version fix
	* added Event dependency; generated linux tests
	* fixed AnyError to NSError auto bridging
	* Event once
	* new settling futures
	* better target config
	* configs for reactive-swift; project for all Apple platforms; Linux configuration
	* Promise tests
	* more correct context selection
	* moved XCTest3 to Cartfile.private
	* Future tests
	* Swift 3 support fixes and tests
	* carthage compatibility
	* isCompleted; onComplete works on completed futures; context selection fixed for continuations;
	* recover
	* more APIs
	* added context selector
	* initial checkin
	* dependencies
	* better ignore
	* added Apache 2.0 license
	* initial commit