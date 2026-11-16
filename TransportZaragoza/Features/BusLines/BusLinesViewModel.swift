import Foundation
import Combine
import OSLog

@MainActor
final class BusLinesViewModel: ObservableObject {
    @Published private(set) var state: LoadState<[String]> = .idle
    private let repository: any BusStopsProviding
    private var requestID: UUID?

    init(busStopsRepository: any BusStopsProviding) { repository = busStopsRepository }

    func getBusLines(updateData: Bool = false) async {
        let id = UUID()
        requestID = id
        state = .loading
        do {
            let stops = try await repository.getBusStops(updateData: updateData)
            try Task.checkCancellation()
            guard requestID == id else { return }
            let lines = Set(stops.flatMap { $0.title.extractLines() }).sorted {
                $0.localizedStandardCompare($1) == .orderedAscending
            }
            state = lines.isEmpty ? .empty : .content(lines)
        } catch {
            guard requestID == id else { return }
            if error is CancellationError || Task.isCancelled { state = .idle; return }
            Logger(subsystem: "TransportZaragoza", category: "BusLines").error("Loading failed: \(String(reflecting: error), privacy: .private)")
            state = .failed
        }
    }
}
