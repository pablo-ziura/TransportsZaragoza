import Foundation

actor TramStopsRepository {
    private let remoteService: any TramStopsRemoteService
    private let localService: UserDefaultsTramStopsLocalService
    private var catalogRequestID: UUID?

    init(remoteService: any TramStopsRemoteService, defaultsSuiteName: String? = nil) {
        self.remoteService = remoteService
        localService = UserDefaultsTramStopsLocalService(suiteName: defaultsSuiteName)
    }

    func getTramStops(updateData: Bool = false) async throws -> [TramStop] {
        if !updateData, let cached = try? localService.getTramStops(), !cached.isEmpty { return cached }
        let requestID = UUID()
        catalogRequestID = requestID
        let stops = try await remoteService.getTramStops()
        try Task.checkCancellation()
        if catalogRequestID == requestID { try localService.save(tramStops: stops) }
        return stops
    }

    func isFavorite(tramStop: TramStop) -> Bool { localService.isFavorite(tramStop: tramStop) }
    func addFavorite(tramStop: TramStop) { localService.addFavorite(tramStop: tramStop) }
    func removeFavorite(tramStop: TramStop) { localService.removeFavorite(tramStop: tramStop) }
    func getFavorites() -> [TramStop] { localService.getFavorites() }
}
