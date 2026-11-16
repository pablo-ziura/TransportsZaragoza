import Foundation
import Combine
import OSLog

@MainActor
final class SplashScreenViewModel: ObservableObject {
    
    @Published var busStops: [BusStop] = []
    @Published var tramStops: [TramStop] = []
    @Published var isLoading = false
    @Published var error: Error?
    @Published var updateData = false

    private let busStopsRepository: BusStopsRepository
    private let tramStopsRepository: TramStopsRepository

    init(busStopsRepository: BusStopsRepository, tramStopsRepository: TramStopsRepository) {
        self.busStopsRepository = busStopsRepository
        self.tramStopsRepository = tramStopsRepository
    }
    
    func getBusStops() async {
        isLoading = true
        do {
            busStops = try await busStopsRepository.getBusStops(updateData: updateData)
        } catch (let error) {
            if error is CancellationError || Task.isCancelled { isLoading = false; return }
            self.error = error
            Logger(subsystem: "TransportZaragoza", category: "Startup").error("Prefetch failed: \(String(reflecting: error), privacy: .private)")
        }
        isLoading = false
    }
    
    func getTramStops() async {
        isLoading = true
        do {
            tramStops = try await tramStopsRepository.getTramStops(updateData: updateData)
        } catch (let error) {
            if error is CancellationError || Task.isCancelled { isLoading = false; return }
            self.error = error
            Logger(subsystem: "TransportZaragoza", category: "Startup").error("Prefetch failed: \(String(reflecting: error), privacy: .private)")
        }
        isLoading = false
    }
}
