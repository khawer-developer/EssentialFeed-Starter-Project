//
//  URLSessionHTTPClientTests.swift
//  EssentialFeedTests
//
//  Created by Khawer Khaliq on 11/10/2025.
//

import XCTest
import EssentialFeed

class URLSessionHTTPClient {
    private let session: URLSession
    
    init(session: URLSession) {
        self.session = session
    }
    
    func get(
        from url: URL,
        completion: @escaping (HTTPClientResult) -> Void
    ) {
        session.dataTask(with: url) { _, _, error in
            if let error {
                completion(.failure(error))
            }
        }.resume()
    }
}

class URLSessionHTTPClientTests: XCTestCase {
    func test_getFromURL_resumesDataTaskWithURL() {
        let url = URL(string: "https://any-url.com")!
        let session = URLSessionSpy()
        let task = URLSessionDataTaskSpy()
        session.stub(
            url: url,
            task: task
        )
        let sut = URLSessionHTTPClient(session: session)
        
        sut.get(from: url) { _ in }
        
        XCTAssertEqual(
            task.resumeCallCount,
            1
        )
    }
    
    func test_getFromURL_failsOnRequestError() {
        let url = URL(string: "https://any-url.com")!
        let session = URLSessionSpy()
        let error = NSError(
            domain: "any error",
            code: 1
        )
        session.stub(
            url: url,
            error: error
        )
        let sut = URLSessionHTTPClient(session: session)
        
        let exp = expectation(description: "Wait for completion")
        sut.get(from: url) { result in
            switch result {
            case let .failure(receivedError as NSError):
                XCTAssertEqual(
                    receivedError,
                    error
                )
            default:
                XCTFail("Expected failure with error \(error) but got \(result) instead")
            }
            exp.fulfill()
        }
        wait(
            for: [exp],
            timeout: 1.0
        )
    }
    
    // MARK: - Helpers
    
    private class URLSessionSpy: URLSession, @unchecked Sendable {
        private struct Stub {
            let task: URLSessionDataTask
            let error: Error?
        }
        
        private var stubs = [URL: Stub]()
        
        func stub(
            url: URL,
            task: URLSessionDataTask = FakeURLSessionDataTask(),
            error: Error? = nil
        ) {
            stubs[url] = Stub(
                task: task,
                error: error
            )
        }
        
        override func dataTask(
            with url: URL,
            completionHandler: @escaping (Data?, URLResponse?, Error?) -> Void
        ) -> URLSessionDataTask {
            guard let stub = stubs[url] else {
                fatalError("Could not find stub for \(url)")
            }
            completionHandler(nil, nil, stub.error)
            return stub.task
        }
    }
    
    private class FakeURLSessionDataTask: URLSessionDataTask, @unchecked Sendable {
        override func resume() { }
    }
    
    private class URLSessionDataTaskSpy: URLSessionDataTask, @unchecked Sendable {
        var resumeCallCount = 0
        
        override func resume() {
            resumeCallCount += 1
        }
    }
}
