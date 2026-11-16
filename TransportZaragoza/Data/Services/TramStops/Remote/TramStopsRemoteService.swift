import Foundation

protocol TramStopsRemoteService: Sendable {
    func getTramStops() async throws -> [TramStop]
}
