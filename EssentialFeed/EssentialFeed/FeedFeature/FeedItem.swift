//
//  Copyright © Essential Developer. All rights reserved.
//

import Foundation

public struct FeedItem: Decodable, Equatable {
	let id: UUID
	let description: String?
	let location: String?
	let imageURL: URL
}
