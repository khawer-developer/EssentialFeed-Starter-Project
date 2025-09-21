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
            toCompleteWithResult: .failure(.connectivity),
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
                toCompleteWithResult: .failure(.invalidData),
                when: {
                    client.complete(
                        withStatusCode: statusCode,
                        data: makeItemsJSON([]),
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
            toCompleteWithResult: .failure(.invalidData),
            when: {
                client.complete(
                    withStatusCode: 200,
                    data: invalidJSON
                )
            }
        )
    }
    
    func test_load_deliversNoItemsOn200HTTPResponseWithEmptyJSONList() {
        let emptyListJSON = makeItemsJSON([])
        let (sut, client) = makeSUT()
        
        expect(
            sut,
            toCompleteWithResult: .success([]),
            when: {
                client.complete(
                    withStatusCode: 200,
                    data: emptyListJSON
                )
            }
        )
    }
    
    func test_load_deliversItemsOn200HTTPResponseWithValidJSONItems() {
        let item1 = makeItem(
            id: UUID(),
            description: nil,
            location: nil,
            imageURL: URL(string: "https://item1-url.com")!
        )
        let item2 = makeItem(
            id: UUID(),
            description: "item2 description",
            location: "item2 location",
            imageURL: URL(string: "https://item2-url.com")!
        )
        let items = [
            item1.model,
            item2.model
        ]
        let itemsJSON = makeItemsJSON([
            item1.json,
            item2.json
        ])
        let (sut, client) = makeSUT()
        
        expect(
            sut,
            toCompleteWithResult: .success(items),
            when: {
                client.complete(
                    withStatusCode: 200,
                    data: itemsJSON)
            }
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
    
    private func makeItem(
        id: UUID,
        description: String? = nil,
        location: String? = nil,
        imageURL: URL
    ) -> (model: FeedItem, json: [String: Any]) {
        let item = FeedItem(
            id: id,
            description: description,
            location: location,
            imageURL: imageURL
        )
        let itemJSON = [
            "id": id.uuidString,
            "description": description,
            "location": location,
            "image": imageURL.absoluteString
        ].compactMapValues { $0 }
        return (item, itemJSON)
    }
    
    private func makeItemsJSON(_ items: [[String: Any]]) -> Data {
        let itemsJSON = ["items": items]
        return try! JSONSerialization.data(withJSONObject: itemsJSON)
    }
    
    private func expect(
        _ sut: RemoteFeedLoader,
        toCompleteWithResult result: RemoteFeedLoader.Result,
        when action: () -> Void,
        file: StaticString = #file,
        line: UInt = #line
    ) {
        var capturedResults = [RemoteFeedLoader.Result]()
        sut.load { capturedResults.append($0) }
        
        action()
        
        XCTAssertEqual(
            capturedResults,
            [result],
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
            atIndex index: Int = 0
        ) {
            messages[index].completion(.failure(error))
        }
        
        func complete(
            withStatusCode statusCode: Int,
            data: Data,
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
