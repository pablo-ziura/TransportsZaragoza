import Foundation

enum LoadState<Value: Sendable>: Sendable {
    case idle
    case loading
    case content(Value)
    case empty
    case failed
}

extension LoadState: Equatable where Value: Equatable {}
