//
//  XCTestCase+MemoryLeakTesting.swift
//  EssentialFeedTests
//
//  Created by Khawer Khaliq on 19/10/2025.
//

import XCTest

extension XCTestCase {
    func testForMemoryLeaks(
        _ instance: AnyObject,
        file: StaticString = #file,
        line: UInt = #line
    ) {
        addTeardownBlock { [weak instance] in
            XCTAssertNil(
                instance,
                "Instance should have been deallocated - potential memory leak",
                file: file,
                line: line
            )
        }
    }
}


