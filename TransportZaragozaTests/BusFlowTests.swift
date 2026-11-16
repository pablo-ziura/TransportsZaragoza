import Foundation
import Testing
import Lottie
import TransportNetwork
@testable import TransportZaragoza

private actor ControlledRepository: BusStopsProviding {
    private var pending: [String: CheckedContinuation<BusStopData, any Error>] = [:]
    private var waiters: [String: CheckedContinuation<Void, Never>] = [:]
    var stops: [BusStop] = [.example]

    func getBusStops(updateData: Bool) -> [BusStop] { stops }
    func getBusStopDataById(busStopId: String) async throws -> BusStopData {
        try await withCheckedThrowingContinuation {
            pending[busStopId] = $0
            waiters.removeValue(forKey: busStopId)?.resume()
        }
    }
    func waitForRequest(_ id: String) async {
        if pending[id] != nil { return }
        await withCheckedContinuation { waiters[id] = $0 }
    }
    func complete(_ id: String, arrivals: [ArrivalBus]) {
        pending.removeValue(forKey: id)?.resume(returning: BusStopData(
            geometry: Geometry(type: "Point", coordinates: [0, 0]), destinos: arrivals
        ))
    }
    func fail(_ id: String) { pending.removeValue(forKey: id)?.resume(throwing: URLError(.notConnectedToInternet)) }
    func isFavorite(busStop: BusStop, busLine: String) -> Bool { false }
    func addFavorite(busStop: BusStop, busLine: String) {}
    func removeFavorite(busStop: BusStop, busLine: String) {}
    func getFavorites() -> [BusStop] { [] }
}

@Suite(.timeLimit(.minutes(1)))
@MainActor
struct BusFlowTests {
    private let arrival = ArrivalBus(linea: "58", destino: "FUENTE JUNQUERA", primero: "3 minutos.", segundo: "12 minutos.")

    @Test func loadingThenContent() async {
        let repository = ControlledRepository()
        let model = BusLineDetailViewModel(busStopsRepository: repository, busLine: "58")
        let task = Task { await model.getBusStopData(busStopId: "688") }
        await repository.waitForRequest("688")
        #expect(model.arrivalsState == .loading)
        await repository.complete("688", arrivals: [arrival])
        await task.value
        #expect(model.arrivalsState == .content([arrival]))
    }

    @Test func failureCanBeRetriedAndBecomeEmpty() async {
        let repository = ControlledRepository()
        let model = BusLineDetailViewModel(busStopsRepository: repository, busLine: "58")
        let first = Task { await model.getBusStopData(busStopId: "688") }
        await repository.waitForRequest("688")
        await repository.fail("688")
        await first.value
        #expect(model.arrivalsState == .failed)
        let retry = Task { await model.getBusStopData(busStopId: "688") }
        await repository.waitForRequest("688")
        #expect(model.arrivalsState == .loading)
        await repository.complete("688", arrivals: [])
        await retry.value
        #expect(model.arrivalsState == .empty)
    }

    @Test(arguments: [false, true])
    func oldResponseCannotOverwriteCurrentSelection(oldRequestFails: Bool) async {
        let repository = ControlledRepository()
        let model = BusLineDetailViewModel(busStopsRepository: repository, busLine: "58")
        let old = Task { await model.getBusStopData(busStopId: "old") }
        await repository.waitForRequest("old")
        let current = Task { await model.getBusStopData(busStopId: "current") }
        await repository.waitForRequest("current")
        await repository.complete("current", arrivals: [arrival])
        await current.value
        if oldRequestFails { await repository.fail("old") }
        else { await repository.complete("old", arrivals: []) }
        await old.value
        #expect(model.arrivalsState == .content([arrival]))
    }

    @Test func cancellationDoesNotPublishContentOrError() async {
        let repository = ControlledRepository()
        let model = BusLineDetailViewModel(busStopsRepository: repository, busLine: "58")
        let task = Task { await model.getBusStopData(busStopId: "688") }
        await repository.waitForRequest("688")
        task.cancel()
        await repository.complete("688", arrivals: [arrival])
        await task.value
        #expect(model.arrivalsState == .idle)
    }

    @Test func listsAndFiltersLinesAndStops() async {
        let repository = ControlledRepository()
        let lines = BusLinesViewModel(busStopsRepository: repository)
        await lines.getBusLines()
        #expect(lines.state == .content(["22", "41", "58"]))
        let stops = BusLineDetailViewModel(busStopsRepository: repository, busLine: "58")
        await stops.getBusStopsByLine()
        #expect(stops.stopsState == .content([.example]))
        let empty = BusLineDetailViewModel(busStopsRepository: repository, busLine: "999")
        await empty.getBusStopsByLine()
        #expect(empty.stopsState == .empty)
    }

    @Test func bundledAnimationLoads() {
        #expect(LottieAnimation.named("Animation", bundle: Bundle.main) != nil)
    }
}

private struct RemoteStub: BusStopsRemoteService {
    func getBusStops() -> [BusStop] { [.example] }
    func getBusStopDataById(busStopId: String) -> BusStopData {
        BusStopData(geometry: Geometry(type: "Point", coordinates: [0, 0]), destinos: [])
    }
}

private struct OfflineRemote: BusStopsRemoteService {
    func getBusStops() async throws -> [BusStop] { throw URLError(.notConnectedToInternet) }
    func getBusStopDataById(busStopId: String) async throws -> BusStopData { throw URLError(.notConnectedToInternet) }
}

@Suite struct PersistenceTests {
    @Test @MainActor func cachedCatalogRemainsAvailableOffline() async throws {
        let suite = "OfflineTests-\(UUID())"
        let defaults = try #require(UserDefaults(suiteName: suite))
        defer { defaults.removePersistentDomain(forName: suite) }
        defaults.set(try JSONEncoder().encode([BusStop.example]), forKey: "busStops")
        let repository = BusStopsRepository(remoteService: OfflineRemote(), defaultsSuiteName: suite)
        let model = BusLinesViewModel(busStopsRepository: repository)
        await model.getBusLines()
        #expect(model.state == .content(["22", "41", "58"]))
        await model.getBusLines(updateData: true)
        #expect(model.state == .failed)
        await model.getBusLines()
        #expect(model.state == .content(["22", "41", "58"]))
    }

    @Test func preservesLegacyFavoritesAndSeparatesLines() async throws {
        let suite = "BusTests-\(UUID())"
        let defaults = try #require(UserDefaults(suiteName: suite))
        defer { defaults.removePersistentDomain(forName: suite) }
        defaults.set(try JSONEncoder().encode([BusStop.example]), forKey: "favBusStops")
        let repository = BusStopsRepository(remoteService: RemoteStub(), defaultsSuiteName: suite)
        #expect(await repository.isFavorite(busStop: .example, busLine: "22"))
        await repository.addFavorite(busStop: .example, busLine: "58")
        await repository.addFavorite(busStop: .example, busLine: "58")
        #expect(await repository.getFavorites().count == 2)
        await repository.removeFavorite(busStop: .example, busLine: "22")
        #expect(await repository.getFavorites().map(\.busLine) == ["58"])
        let reloaded = BusStopsRepository(remoteService: RemoteStub(), defaultsSuiteName: suite)
        #expect(await reloaded.isFavorite(busStop: .example, busLine: "58"))
    }
}

private actor PageTransport: HTTPTransport {
    private(set) var starts: [String] = []
    func data(for request: URLRequest) async throws -> (Data, URLResponse) {
        let url = request.url!
        let query = URLComponents(url: url, resolvingAgainstBaseURL: false)!.queryItems!
        let start = query.first { $0.name == "start" }!.value!
        starts.append(start)
        let stop: [String: Any] = ["id": "tuzsa-\(start)", "title": "Stop Líneas: 58", "geometry": ["coordinates": [0, 0]]]
        let data = try JSONSerialization.data(withJSONObject: ["totalCount": 2, "start": Int(start)!, "rows": 500, "result": [stop]])
        return (data, HTTPURLResponse(url: url, statusCode: 200, httpVersion: nil, headerFields: nil)!)
    }
}

@Suite struct MunicipalContractTests {
    @Test func fetchesEveryPage() async throws {
        let transport = PageTransport()
        let client = NetworkClient(baseURL: URL(string: "https://example.com")!, transport: transport)
        let stops = try await LiveBusStopsRemoteService(networkClient: client).getBusStops()
        #expect(stops.map(\.id) == ["tuzsa-0", "tuzsa-1"])
        #expect(await transport.starts == ["0", "1"])
    }

    @Test func ruralStopWithoutArrivalsIsEmpty() throws {
        let data = try Data(contentsOf: #require(Bundle.main.url(forResource: "bus-rural", withExtension: "json")))
        #expect(try JSONDecoder().decode(BusStopData.self, from: data).destinos.isEmpty)
    }

    @Test func malformedArrivalsStillFailDecoding() throws {
        let data = try Data(contentsOf: #require(Bundle.main.url(forResource: "bus-invalid", withExtension: "json")))
        #expect(throws: DecodingError.self) { try JSONDecoder().decode(BusStopData.self, from: data) }
    }
}
