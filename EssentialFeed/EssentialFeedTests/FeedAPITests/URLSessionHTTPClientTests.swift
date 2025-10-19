//
//  URLSessionHTTPClientTests.swift
//  EssentialFeedTests
//
//  Created by Khawer Khaliq on 11/10/2025.
//

import XCTest
import EssentialFeed

class URLSessionHTTPClient {
    struct UnexpectedValuesRepresentation: Error { }
    
    private let session: URLSession
    
    init(session: URLSession = .shared) {
        self.session = session
    }
    
    func get(
        from url: URL,
        completion: @escaping (HTTPClientResult) -> Void
    ) {
        session.dataTask(with: url) { _, _, error in
            if let error {
                completion(.failure(error))
            } else {
                completion(.failure(UnexpectedValuesRepresentation()))
            }
        }.resume()
    }
}

class URLSessionHTTPClientTests: XCTestCase {
    override func setUp() {
        super.setUp()
        URLProtocolStub.startInterceptingRequests()
    }
    
    override func tearDown() {
        super.tearDown()
        URLProtocolStub.stopInterceptingRequests()
    }
    
    func test_getFromURL_performsGETRequestWithURL() {
        let url = anyURL
        let exp = expectation(description: "Wait for request")
        URLProtocolStub.observeRequests { request in
            XCTAssertEqual(
                request.url,
                url
            )
            XCTAssertEqual(
                request.httpMethod,
                "GET"
            )
            exp.fulfill()
        }
        
        makeSUT().get(from: url) { _ in }
        
        wait(for: [exp], timeout: 1.0)
    }
    
    func test_getFromURL_failsOnRequestError() {
        let requestError = NSError(
            domain: "any error",
            code: 1
        )
        
        let receivedError = resultErrorFor(
            data: nil,
            resonse: nil,
            error: requestError
        )
        
        XCTAssertEqual(
            (receivedError as NSError?)?.domain,
            requestError.domain
        )
        XCTAssertEqual(
            (receivedError as NSError?)?.code,
            requestError.code
        )
    }
    
    func test_getFromURL_failsOnAllNilValues() {
        XCTAssertNotNil(resultErrorFor(data: nil, resonse: nil, error: nil))
    }
    
    // MARK: - Helpers
    
    private var anyURL: URL {
        URL(string: "https://any-url.com")!
    }
    
    private func makeSUT(
        file: StaticString = #file,
        line: UInt = #line
    ) -> URLSessionHTTPClient {
        let sut = URLSessionHTTPClient()
        testForMemoryLeaks(
            sut,
            file: file,
            line: line
        )
        return sut
    }
    
    private func resultErrorFor(
        data: Data?,
        resonse: URLResponse?,
        error: Error?,
        file: StaticString = #file,
        line: UInt = #line
    ) -> Error? {
        URLProtocolStub.stub(
            data: data,
            response: resonse,
            error: error
        )
        let sut = makeSUT(
            file: file,
            line: line
        )
        let exp = expectation(description: "Wait for completion")
        var receivedError: Error?
        
        sut.get(from: anyURL) { result in
            switch result {
            case let .failure(error):
                receivedError = error
            default:
                XCTFail("Expected failure but got \(result) instead",
                file: file,
                line: line)
            }
            exp.fulfill()
        }
        wait(
            for: [exp],
            timeout: 1.0
        )
        return receivedError
    }
    
    private class URLProtocolStub: URLProtocol {
        private struct Stub {
            let data: Data?
            let response: URLResponse?
            let error: Error?
        }
        
        private static var stub: Stub?
        private static var requestObserver: ((URLRequest) -> Void)?
        
        static func stub(
            data: Data?,
            response: URLResponse?,
            error: Error?
        ) {
            stub = Stub(
                data: data,
                response: response,
                error: error
            )
        }
        
        static func observeRequests(observer: @escaping (URLRequest) -> Void) {
            requestObserver = observer
        }
        
        static func startInterceptingRequests() {
            URLProtocol.registerClass(URLProtocolStub.self)
        }
        
        static func stopInterceptingRequests() {
            URLProtocol.unregisterClass(URLProtocolStub.self)
            stub = nil
            requestObserver = nil
        }
        
        override class func canInit(with request: URLRequest) -> Bool {
            requestObserver?(request)
            return true
        }
        
        override class func canonicalRequest(for request: URLRequest) -> URLRequest {
            request
        }
        
        override func startLoading() {
            if let data = URLProtocolStub.stub?.data {
                client?.urlProtocol(
                    self,
                    didLoad: data
                )
            }
            if let response = URLProtocolStub.stub?.response {
                client?.urlProtocol(
                    self,
                    didReceive: response,
                    cacheStoragePolicy: .notAllowed
                )
            }
            if let error = URLProtocolStub.stub?.error {
                client?.urlProtocol(
                    self,
                    didFailWithError: error
                )
            }
            client?.urlProtocolDidFinishLoading(self)
        }
        
        override func stopLoading() { }
    }
}
