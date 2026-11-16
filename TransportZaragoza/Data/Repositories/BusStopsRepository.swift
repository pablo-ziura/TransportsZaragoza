import Foundation

protocol BusStopsProviding: Sendable {
    func getBusStops(updateData: Bool) async throws -> [BusStop]
    func getBusStopDataById(busStopId: String) async throws -> BusStopData
    func isFavorite(busStop: BusStop, busLine: String) async -> Bool
    func addFavorite(busStop: BusStop, busLine: String) async
    func removeFavorite(busStop: BusStop, busLine: String) async
    func getFavorites() async -> [BusStop]
}

actor BusStopsRepository: BusStopsProviding {
    private let remoteService: any BusStopsRemoteService
    private let localService: UserDefaultsBusStopsLocalService
    private var catalogRequestID: UUID?

    init(remoteService: any BusStopsRemoteService, defaultsSuiteName: String? = nil) {
        self.remoteService = remoteService
        localService = UserDefaultsBusStopsLocalService(suiteName: defaultsSuiteName)
    }

    func getBusStops(updateData: Bool = false) async throws -> [BusStop] {
        if !updateData, let cached = try? localService.getBusStops(), !cached.isEmpty { return cached }
        let requestID = UUID()
        catalogRequestID = requestID
        let stops = try await remoteService.getBusStops()
        try Task.checkCancellation()
        if catalogRequestID == requestID { try localService.save(busStops: stops) }
        return stops
    }

    func getBusStopDataById(busStopId: String) async throws -> BusStopData {
        try await remoteService.getBusStopDataById(busStopId: busStopId)
    }

    func isFavorite(busStop: BusStop, busLine: String) -> Bool {
        localService.isFavorite(busStop: busStop, busLine: busLine)
    }

    func addFavorite(busStop: BusStop, busLine: String) {
        localService.addFavorite(busStop: busStop, busLine: busLine)
    }

    func removeFavorite(busStop: BusStop, busLine: String) {
        localService.removeFavorite(busStop: busStop, busLine: busLine)
    }

    func getFavorites() -> [BusStop] { localService.getFavorites() }
}
