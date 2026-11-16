import Foundation
import Testing
@testable import TransportNetwork

private struct Payload: Codable, Sendable, Equatable { let value: String }

private actor StubTransport: HTTPTransport {
    let body: Data
    let status: Int
    let failure: URLError?
    let nonHTTP: Bool
    private(set) var requests: [URLRequest] = []

    init(body: String = #"{"value":"OK"}"#, status: Int = 200, failure: URLError? = nil, nonHTTP: Bool = false) {
        self.body = Data(body.utf8)
        self.status = status
        self.failure = failure
        self.nonHTTP = nonHTTP
    }

    func data(for request: URLRequest) async throws -> (Data, URLResponse) {
        requests.append(request)
        if let failure { throw failure }
        let url = request.url!
        let response = nonHTTP
            ? URLResponse(url: url, mimeType: nil, expectedContentLength: body.count, textEncodingName: nil)
            : HTTPURLResponse(url: url, statusCode: status, httpVersion: nil, headerFields: nil)!
        return (body, response)
    }
}

private actor SuspendedTransport: HTTPTransport {
    private var started = false
    private var waiter: CheckedContinuation<Void, Never>?

    func waitUntilStarted() async {
        if started { return }
        await withCheckedContinuation { waiter = $0 }
    }

    func data(for request: URLRequest) async throws -> (Data, URLResponse) {
        started = true
        waiter?.resume()
        try await Task.sleep(for: .seconds(60))
        throw URLError(.timedOut)
    }
}

@Suite("HTTP client", .timeLimit(.minutes(1)))
struct NetworkClientTests {
    private let baseURL = URL(string: "https://example.com/api")!

    @Test func decodesSuccessAndBuildsRequest() async throws {
        let transport = StubTransport()
        let client = NetworkClient(baseURL: baseURL, transport: transport)
        let result: Payload = try await client.get(endpoint: "stops/688.json", params: ["q": "A&B + C"], headers: ["X-Test": "yes"])
        #expect(result == Payload(value: "OK"))
        let request = try #require(await transport.requests.first)
        #expect(request.url?.path == "/api/stops/688.json")
        #expect(URLComponents(url: request.url!, resolvingAgainstBaseURL: false)?.queryItems?.first?.value == "A&B + C")
        #expect(request.httpMethod == "GET")
        #expect(request.value(forHTTPHeaderField: "Accept") == "application/json")
        #expect(request.value(forHTTPHeaderField: "X-Test") == "yes")
    }

    @Test(arguments: [401, 404, 503])
    func preservesHTTPFailure(status: Int) async throws {
        let client = NetworkClient(baseURL: baseURL, transport: StubTransport(body: "service unavailable", status: status))
        do {
            let _: Payload = try await client.get(endpoint: "stops")
            Issue.record("Expected HTTP failure")
        } catch let NetworkError.http(url, code, body) {
            #expect(url.path == "/api/stops")
            #expect(code == status)
            #expect(String(decoding: body, as: UTF8.self) == "service unavailable")
        }
    }

    @Test(arguments: ["not JSON", #"{"value":123}"#])
    func preservesDecodingFailure(body: String) async throws {
        let client = NetworkClient(baseURL: baseURL, transport: StubTransport(body: body))
        do {
            let _: Payload = try await client.get(endpoint: "stops")
            Issue.record("Expected decoding failure")
        } catch let NetworkError.decoding(url, error) {
            #expect(url.path == "/api/stops")
            if body.contains("123") {
                guard case .typeMismatch(_, let context) = error else {
                    Issue.record("Expected typeMismatch"); return
                }
                #expect(context.codingPath.map(\.stringValue) == ["value"])
            }
        }
    }

    @Test func preservesTransportFailure() async throws {
        let client = NetworkClient(baseURL: baseURL, transport: StubTransport(failure: URLError(.notConnectedToInternet)))
        do {
            let _: Payload = try await client.get(endpoint: "stops")
            Issue.record("Expected transport failure")
        } catch let NetworkError.transport(_, underlying) {
            #expect((underlying as? URLError)?.code == .notConnectedToInternet)
        }
    }

    @Test func rejectsNonHTTPResponse() async throws {
        let client = NetworkClient(baseURL: baseURL, transport: StubTransport(nonHTTP: true))
        await #expect(throws: NetworkError.self) { let _: Payload = try await client.get(endpoint: "stops") }
    }

    @Test func propagatesSessionCancellation() async throws {
        let client = NetworkClient(baseURL: baseURL, transport: StubTransport(failure: URLError(.cancelled)))
        await #expect(throws: CancellationError.self) { let _: Payload = try await client.get(endpoint: "stops") }
    }

    @Test func cancelsAnActiveRequest() async throws {
        let transport = SuspendedTransport()
        let client = NetworkClient(baseURL: baseURL, transport: transport)
        let task = Task { let _: Payload = try await client.get(endpoint: "stops") }
        await transport.waitUntilStarted()
        task.cancel()
        await #expect(throws: CancellationError.self) { try await task.value }
    }

    @Test func cancelledTaskDoesNotStartTransport() async throws {
        let transport = StubTransport()
        let client = NetworkClient(baseURL: baseURL, transport: transport)
        let task = Task {
            withUnsafeCurrentTask { $0?.cancel() }
            let _: Payload = try await client.get(endpoint: "stops")
        }
        await #expect(throws: CancellationError.self) { try await task.value }
        #expect(await transport.requests.isEmpty)
    }

    @Test func sendsEncodedBodyAndHeaders() async throws {
        let transport = StubTransport()
        let client = NetworkClient(baseURL: baseURL, transport: transport)
        let _: Payload = try await client.post(endpoint: "stops", data: Payload(value: "request"))
        let request = try #require(await transport.requests.first)
        #expect(request.httpMethod == "POST")
        #expect(request.value(forHTTPHeaderField: "Content-Type") == "application/json")
        #expect(try JSONDecoder().decode(Payload.self, from: #require(request.httpBody)) == Payload(value: "request"))
    }
}
