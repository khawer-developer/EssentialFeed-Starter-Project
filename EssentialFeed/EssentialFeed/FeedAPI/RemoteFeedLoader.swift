//
//  RemoteFeedLoader.swift
//  EssentialFeed
//
//  Created by Khawer Khaliq on 14/09/2025.
//

import Foundation

public final class RemoteFeedLoader {
    public enum Error: Swift.Error {
        case connectivity
        case invalidData
    }
    
    public enum Result: Equatable {
        case success([FeedItem])
        case failure(Error)
    }
    
    private let url: URL
    private let client: HTTPClient
    
    public init(
        url: URL,
        client: HTTPClient
    ) {
        self.url = url
        self.client = client
    }
    
    public func load(completion: @escaping (Result) -> Void) {
        client.get(from: url) { [weak self] result in
            guard self != nil else {
                return
            }
            switch result {
            case let .success(data, response):
                completion(FeedItemsMapper.map(
                    data,
                    from: response))
            case .failure:
                completion(.failure(.connectivity))
            }
        }
    }
}


