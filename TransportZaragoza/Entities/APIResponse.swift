import Foundation

struct APIResponse<Item: Decodable & Sendable>: Decodable, Sendable {
    let totalCount: Int
    let start: Int
    let rows: Int
    let result: [Item]
}
