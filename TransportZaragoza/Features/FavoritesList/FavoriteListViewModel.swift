import Foundation
import Combine

@MainActor
final class FavoriteListViewModel: ObservableObject {
    
    @Published var favoriteTramStops: [TramStop] = []
    @Published var favoriteBusStops: [BusStop] = []
    @Published var isLoading = false
    @Published var error: Error?
    
    private let tramStopsRepository: TramStopsRepository
    private let busStopsRepository: BusStopsRepository

    init(tramStopsRepository: TramStopsRepository, busStopsRepository: BusStopsRepository) {
        self.tramStopsRepository = tramStopsRepository
        self.busStopsRepository = busStopsRepository
    }
    
    func getFavoritesTramStops() async {
        favoriteTramStops = await tramStopsRepository.getFavorites()
    }
    
    func getFavoritesBusStops() async {
        favoriteBusStops = await busStopsRepository.getFavorites()
    }
    
}
