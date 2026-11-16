import Foundation
import Combine
import OSLog

@MainActor
final class TramStopsViewModel: ObservableObject {
    
    @Published var tramStopsList: [TramStop] = []
    @Published var isLoading = false
    @Published var error: Error?
    @Published var showErrorAlert = false
    
    private var requestID: UUID?
    private let tramStopsRepository: TramStopsRepository
    
    init(tramStopsRepository: TramStopsRepository) {
        self.tramStopsRepository = tramStopsRepository
    }
    
    func getTramStops() async {
        let id = UUID()
        requestID = id
        isLoading = true
        do {
            let stops = try await tramStopsRepository.getTramStops()
            try Task.checkCancellation()
            guard requestID == id else { return }
            tramStopsList = stops
            showErrorAlert = false
        } catch {
            guard requestID == id else { return }
            if error is CancellationError || Task.isCancelled { isLoading = false; return }
            self.error = error
            Logger(subsystem: "TransportZaragoza", category: "Tram").error("Loading failed: \(String(reflecting: error), privacy: .private)")
            showErrorAlert = true
        }
        isLoading = false
    }
    
    func isFavorite(tramStop: TramStop) async -> Bool {
        return await tramStopsRepository.isFavorite(tramStop: tramStop)
    }
    
    func addFavorite(tramStop: TramStop) async {
        await tramStopsRepository.addFavorite(tramStop: tramStop)
    }
    
    func removeFavorite(tramStop: TramStop) async {
        await tramStopsRepository.removeFavorite(tramStop: tramStop)
    }
}
