import Foundation
import TransportNetwork

struct LiveTramStopsRemoteService: TramStopsRemoteService {
    let networkClient: any NetworkClientProtocol

    func getTramStops() async throws -> [TramStop] {
        var stops: [TramStop] = []
        var start = 0
        while true {
            try Task.checkCancellation()
            let page: APIResponse<TramStop> = try await networkClient.get(
                endpoint: "parada-tranvia.json",
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
}
