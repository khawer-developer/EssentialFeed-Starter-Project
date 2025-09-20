//
//  RemoteFeedLoader.swift
//  EssentialFeed
//
//  Created by Khawer Khaliq on 14/09/2025.
//

import Foundation

public protocol HTTPClient {
    func get(
        from url: URL,
        completion: (Error) -> Void
    )
}

public final class RemoteFeedLoader {
    public enum Error: Swift.Error {
        case connectivity
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
    
    public func load(completion: (Error) -> Void = { _ in }) {
        client.get(from: url) { error in
            completion(.connectivity)
        }
    }
}


