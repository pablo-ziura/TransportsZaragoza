import Foundation
import Combine
import OSLog

@MainActor
final class BusLineDetailViewModel: ObservableObject {
    @Published private(set) var stopsState: LoadState<[BusStop]> = .idle
    @Published private(set) var arrivalsState: LoadState<[ArrivalBus]> = .idle
    private let repository: any BusStopsProviding
    private let busLine: String
    private var stopsRequestID: UUID?
    private var arrivalsRequestID: UUID?

    init(busStopsRepository: any BusStopsProviding, busLine: String) {
        repository = busStopsRepository
        self.busLine = busLine
    }

    func getBusStopsByLine() async {
        let id = UUID()
        stopsRequestID = id
        stopsState = .loading
        do {
            let stops = try await repository.getBusStops(updateData: false)
                .filter { $0.title.extractLines().contains(busLine) }
                .sorted { $0.title.localizedStandardCompare($1.title) == .orderedAscending }
            try Task.checkCancellation()
            guard stopsRequestID == id else { return }
            stopsState = stops.isEmpty ? .empty : .content(stops)
        } catch {
            guard stopsRequestID == id else { return }
            if error is CancellationError || Task.isCancelled { stopsState = .idle; return }
            log(error)
            stopsState = .failed
        }
    }

    func getBusStopData(busStopId: String) async {
        let id = UUID()
        arrivalsRequestID = id
        arrivalsState = .loading
        do {
            let detail = try await repository.getBusStopDataById(busStopId: busStopId)
            try Task.checkCancellation()
            guard arrivalsRequestID == id else { return }
            arrivalsState = detail.destinos.isEmpty ? .empty : .content(detail.destinos)
        } catch {
            guard arrivalsRequestID == id else { return }
            if error is CancellationError || Task.isCancelled { arrivalsState = .idle; return }
            log(error)
            arrivalsState = .failed
        }
    }

    func isFavorite(busStop: BusStop, busLine: String) async -> Bool {
        await repository.isFavorite(busStop: busStop, busLine: busLine)
    }

    func setFavorite(_ favorite: Bool, busStop: BusStop, busLine: String) async {
        if favorite { await repository.addFavorite(busStop: busStop, busLine: busLine) }
        else { await repository.removeFavorite(busStop: busStop, busLine: busLine) }
    }

    private func log(_ error: any Error) {
        Logger(subsystem: "TransportZaragoza", category: "BusDetail").error("Loading failed: \(String(reflecting: error), privacy: .private)")
    }
}
