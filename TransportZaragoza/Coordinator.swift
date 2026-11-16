import Foundation
import TransportNetwork
import SwiftUI

@MainActor
final class Coordinator: ObservableObject {
    
    private let busStopsRepository: BusStopsRepository
    private let tramStopsRepository: TramStopsRepository
    
    init() {
        
        let baseURL = URL(string: "https://www.zaragoza.es/sede/servicio/urbanismo-infraestructuras/transporte-urbano")!
        let networkClient: NetworkClient
        var suiteName: String?
        #if DEBUG
        if ProcessInfo.processInfo.arguments.contains("--ui-testing") || ProcessInfo.processInfo.environment["XCTestConfigurationFilePath"] != nil {
            networkClient = NetworkClient(baseURL: baseURL, transport: FixtureTransport())
            suiteName = "TransportZaragoza.UITests"
            if ProcessInfo.processInfo.arguments.contains("--reset-storage") {
                UserDefaults(suiteName: suiteName!)?.removePersistentDomain(forName: suiteName!)
            }
        } else {
            networkClient = NetworkClient(baseURL: baseURL)
        }
        #else
        networkClient = NetworkClient(baseURL: baseURL)
        #endif
        tramStopsRepository = TramStopsRepository(
            remoteService: LiveTramStopsRemoteService(networkClient: networkClient), defaultsSuiteName: suiteName
        )
        busStopsRepository = BusStopsRepository(
            remoteService: LiveBusStopsRemoteService(networkClient: networkClient), defaultsSuiteName: suiteName
        )
    }

    func createSplashScreenViewModel() -> SplashScreenViewModel {
        SplashScreenViewModel(
            busStopsRepository: busStopsRepository,
            tramStopsRepository: tramStopsRepository
        )
    }
    
    func createSplashScreenView(isActive: Binding<Bool>) -> SplashScreenView {
        SplashScreenView(
            viewModel: createSplashScreenViewModel(),
            isActive: isActive
        )
    }
    
    private func createTramStopsListViewModel() -> TramStopsViewModel {
        TramStopsViewModel(tramStopsRepository: tramStopsRepository)
    }
    
    func createTramStopListView() -> TramStopsView {
        TramStopsView(
            viewModel: createTramStopsListViewModel()
        )
    }
    
    func createTramStopRowView(tramStop: TramStop) -> TramStopRowView {
        TramStopRowView(
            tramStop: tramStop,
            viewModel: createTramStopsListViewModel()
        )
    }
    
    func createTramStopDetailView(tramStop: TramStop) -> TramStopDetailView {
        TramStopDetailView(tramStop: tramStop)
    }
    
    private func createBusLinesViewModel() -> BusLinesViewModel {
        BusLinesViewModel(busStopsRepository: busStopsRepository)
    }
    
    func createBusLinesView() -> BusLinesView {
        BusLinesView(viewModel: createBusLinesViewModel())
    }
    
    private func createBusLineDetailViewModel(busLine: String) -> BusLineDetailViewModel {
        BusLineDetailViewModel(
            busStopsRepository: busStopsRepository,
            busLine: busLine)
    }
    
    func createBusLineStopRowView(busStop: BusStop, busLine: String) -> BusLineStopRowView {
        BusLineStopRowView(
            busStop: busStop,
            busLine: busLine,
            viewModel: createBusLineDetailViewModel(busLine: busLine)
        )
    }
    
    func createBusLineStopDetailView(busStop: BusStop) -> BusLineStopDetailView {
        BusLineStopDetailView(
            busStop: busStop,
            viewModel: createBusLineDetailViewModel(busLine: busStop.busLine ?? "Unknown")
        )
    }
    
    func createBusLineDetailView(busLine: String) -> BusLineDetailView {
        BusLineDetailView(
            viewModel: createBusLineDetailViewModel(busLine: busLine),
            busLine: busLine
        )
    }
    
    private func createFavoriteListViewModel() -> FavoriteListViewModel {
        FavoriteListViewModel(
            tramStopsRepository: tramStopsRepository,
            busStopsRepository: busStopsRepository
        )
    }
    
    func createFavoriteListView() -> FavoriteListView {
        FavoriteListView(viewModel: createFavoriteListViewModel())
    }
}
