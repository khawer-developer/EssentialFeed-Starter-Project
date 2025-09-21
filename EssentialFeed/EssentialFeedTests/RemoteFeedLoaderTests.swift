//
//  RemoteFeedLoaderTests.swift
//  EssentialFeedTests
//
//  Created by Khawer Khaliq on 14/09/2025.
//

import XCTest
import EssentialFeed

class RemoteFeedLoaderTests: XCTestCase {
    func test_init_doesNotRequestDataFromURL() {
        let (_, client) = makeSUT()
        
        XCTAssertTrue(client.requestedURLs.isEmpty)
    }
    
    func test_load_requestsDataFromURL() {
        let url = URL(string: "https://a-given-url.com")!
        let (sut, client) = makeSUT(url: url)
        
        sut.load { _ in }
        
        XCTAssertEqual(
            client.requestedURLs,
            [url]
        )
    }
    
    func test_loadTwice_requestsDataFromURLTwice() {
        let url = URL(string: "https://a-given-url.com")!
        let (sut, client) = makeSUT(url: url)
        
        sut.load { _ in }
        sut.load { _ in }
        
        XCTAssertEqual(
            client.requestedURLs,
            [url, url]
        )
    }
    
    func test_load_deliversErrorOnClientError() {
        let clientError = NSError(
            domain: "Test",
            code: 0
        )
        let (sut, client) = makeSUT()
        
        expect(
            sut,
            toCompleteWithError: .connectivity,
            when: {
                client.complete(withError: clientError)
            }
        )
    }
    
    func test_load_deliversErrorOnNon200HTTPResponse() {
        let (sut, client) = makeSUT()
        let statusCodes = [199, 201, 300, 400, 500]
        
        statusCodes.enumerated().forEach { index, statusCode in
            expect(
                sut,
                toCompleteWithError: .invalidData,
                when: {
                    client.complete(
                        withStatusCode: statusCode,
                        atIndex: index
                    )
                }
            )
        }
    }
    
    func test_load_deliversErrorOn200HTTPResponseWithInvalidJSON() {
        let invalidJSON = Data("Invalid JSON".utf8)
        let (sut, client) = makeSUT()
        
        expect(
            sut,
            toCompleteWithError: .invalidData,
            when: {
                client.complete(
                    withStatusCode: 200,
                    data: invalidJSON
                )
            }
        )
    }
    
    func test_load_deliversNoItemsOn200HTTPResponseWithEmptyJSONList() {
        let emptyListJSON = Data("{\"items\": []}".utf8)
        let (sut, client) = makeSUT()
        var capturedResults = [RemoteFeedLoader.Result]()
        sut.load { capturedResults.append($0) }
        
        client.complete(
            withStatusCode: 200,
            data: emptyListJSON
        )
        
        XCTAssertEqual(
            capturedResults,
            [.success([])]
        )
    }
    
    // MARK: - Helpers
    
    private func makeSUT(url: URL = URL(string: "https://a-url.com")!) -> (sut: RemoteFeedLoader, client: HTTPClientSpy) {
        let client = HTTPClientSpy()
        let sut = RemoteFeedLoader(
            url: url,
            client: client
        )
        return (sut, client)
    }
    
    private func expect(
        _ sut: RemoteFeedLoader,
        toCompleteWithError error: RemoteFeedLoader.Error,
        when action: () -> Void,
        file: StaticString = #file,
        line: UInt = #line
    ) {
        var capturedResults = [RemoteFeedLoader.Result]()
        sut.load { capturedResults.append($0) }
        
        action()
        
        XCTAssertEqual(
            capturedResults,
            [.failure(error)],
            file: file,
            line: line
        )
    }
    
    private class HTTPClientSpy: HTTPClient {
        var messages = [(url: URL, completion: (HTTPClientResult) -> Void)]()
        
        var requestedURLs : [URL] {
            messages.map { $0.url }
        }
        
        func get(
            from url: URL,
            completion: @escaping (HTTPClientResult) -> Void
        ) {
            messages.append((url, completion))
        }
        
        func complete(
            withError error: Error,
            at index: Int = 0
        ) {
            messages[index].completion(.failure(error))
        }
        
        func complete(
            withStatusCode statusCode: Int,
            data: Data = Data(),
            atIndex index: Int = 0
        ) {
            let response = HTTPURLResponse(
                url: messages[index].url,
                statusCode: statusCode,
                httpVersion: nil,
                headerFields: nil
            )!
            messages[index].completion(.success(data, response))
        }
    }
}
