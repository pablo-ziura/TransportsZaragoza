import Foundation

protocol BusStopsRemoteService: Sendable {
    
    func getBusStops() async throws -> [BusStop]
    func getBusStopDataById(busStopId: String) async throws -> BusStopData
    
}
