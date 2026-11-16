import Foundation
import TransportNetwork

struct LiveBusStopsRemoteService: BusStopsRemoteService {
    let networkClient: any NetworkClientProtocol

    func getBusStops() async throws -> [BusStop] {
        var stops: [BusStop] = []
        var start = 0
        while true {
            try Task.checkCancellation()
            let page: APIResponse<BusStop> = try await networkClient.get(
                endpoint: "poste-autobus.json",
                params: ["start": String(start), "rows": "500", "srsname": "wgs84"], headers: nil
            )
            guard page.start == start, !page.result.isEmpty || start >= page.totalCount else {
                throw MunicipalResponseError.incompletePage
            }
            stops.append(contentsOf: page.result)
            start += page.result.count
            if start >= page.totalCount { break }
        }
        return stops
    }

    func getBusStopDataById(busStopId: String) async throws -> BusStopData {
        try await networkClient.get(
            endpoint: "poste-autobus/\(busStopId).json",
            params: ["srsname": "wgs84"], headers: nil
        )
    }
}

enum MunicipalResponseError: Error {
    case incompletePage
}
