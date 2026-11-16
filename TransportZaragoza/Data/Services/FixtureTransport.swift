#if DEBUG
import Foundation
import TransportNetwork

/// Deterministic HTTP responses for UI tests. Production builds always use URLSession.
actor FixtureTransport: HTTPTransport {
    private var detailRequests = 0

    func data(for request: URLRequest) async throws -> (Data, URLResponse) {
        try Task.checkCancellation()
        let url = request.url!
        let resource: String
        var status = 200
        if url.lastPathComponent == "poste-autobus.json" { resource = "bus-stops" }
        else if url.lastPathComponent == "parada-tranvia.json" { resource = "tram-stops" }
        else {
            detailRequests += 1
            resource = "bus-arrivals"
            if ProcessInfo.processInfo.arguments.contains("--arrival-error-once"), detailRequests == 1 { status = 503 }
        }
        let file = Bundle.main.url(forResource: resource, withExtension: "json")!
        return (try Data(contentsOf: file), HTTPURLResponse(url: url, statusCode: status, httpVersion: nil, headerFields: nil)!)
    }
}
#endif
