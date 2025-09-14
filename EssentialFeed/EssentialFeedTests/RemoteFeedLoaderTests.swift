//
//  RemoteFeedLoaderTests.swift
//  EssentialFeedTests
//
//  Created by Khawer Khaliq on 14/09/2025.
//

import XCTest

class RemoteFeedLoader {
    
}

class HTTPClient {
    var requestedURL: URL?
}

class RemoteFeedLoaderTests: XCTestCase {
    func test_init_doesNotRequestDataFromURL() {
        let client = HTTPClient()
        let _ = RemoteFeedLoader()
        
        XCTAssertNil(client.requestedURL)
    }
}
